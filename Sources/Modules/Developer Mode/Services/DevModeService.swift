//
//  DevModeService.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

/* Proprietary */
import AlertKit

public enum DevModeService {
    // MARK: - Types

    private enum ActionDomain {
        case application
        case subsystem
    }

    // MARK: - Properties

    private static let appActions = LockIsolated<[DevModeAction]>(wrappedValue: AppSubsystem.delegates.devModeAppActions?.appActions ?? [])

    // MARK: - Computed Properties

    private static var subsystemActions: [DevModeAction] {
        DevModeAction.Subsystem.available
    }

    // MARK: - Action Addition

    public static func addAction(_ action: DevModeAction) {
        appActions.projectedValue.withValue {
            $0.removeAll(where: { $0.metadata(isEqual: action) })
            $0.append(action)
        }
    }

    public static func addActions(_ actions: [DevModeAction]) {
        actions.forEach { addAction($0) }
    }

    // MARK: - Action Insertion

    public static func insertAction(
        _ action: DevModeAction,
        after precedingAction: DevModeAction
    ) {
        appActions.projectedValue.withValue {
            guard let index = $0.firstIndex(where: {
                $0.metadata(isEqual: precedingAction)
            }) else { return }

            insertAction(
                action,
                at: index + 1
            )
        }
    }

    public static func insertAction(
        _ action: DevModeAction,
        at index: Int
    ) {
        appActions.projectedValue.withValue {
            guard index < $0.count else {
                guard index == $0.count else { return }
                return addAction(action)
            }

            guard index > -1 else { return }
            $0.removeAll(where: { $0.metadata(isEqual: action) })
            $0.insert(action, at: index)
        }
    }

    public static func insertActions(
        _ actions: [DevModeAction],
        at index: Int
    ) {
        actions.reversed().forEach { insertAction($0, at: index) }
    }

    public static func insertAction(
        _ action: DevModeAction,
        before succeedingAction: DevModeAction
    ) {
        appActions.projectedValue.withValue {
            guard let index = $0.firstIndex(where: {
                $0.metadata(isEqual: succeedingAction)
            }) else { return }

            insertAction(
                action,
                at: index
            )
        }
    }

    // MARK: - Action Removal

    public static func removeAction(at index: Int) {
        appActions.projectedValue.withValue {
            guard index < $0.count,
                  index > -1 else { return }

            $0.remove(at: index)
        }
    }

    public static func removeAction(withTitle: String) {
        appActions.projectedValue.withValue {
            guard $0.contains(where: { $0.title == withTitle }) else { return }
            $0.removeAll(where: { $0.title == withTitle })
        }
    }

    // MARK: - Menu Presentation

    public static func presentActionSheet() {
        Task { @MainActor in
            @Dependency(\.uiApplication) var uiApplication: UIApplication

            guard !uiApplication.isPresentingAlertController else { return }
            guard !appActions.wrappedValue.isEmpty else { return presentActionSheet(domain: .subsystem) }

            let actions: [AKAction] = [
                .init("App Domain") { presentActionSheet(domain: .application) },
                .init("Subsystem Domain") { presentActionSheet(domain: .subsystem) },
                .init("Disable Developer Mode", style: .destructive, effect: DevModeService.promptToToggle),
            ]

            await AKActionSheet(
                title: "Developer Mode Options",
                actions: actions
            ).present(translating: [])
        }
    }

    private static func presentActionSheet(domain: ActionDomain) {
        Task { @MainActor in
            var akActions = [AKAction]()
            appActions.projectedValue.withValue {
                let actions = domain == .application ? $0 : subsystemActions
                akActions = actions.map { devModeAction in
                    .init(
                        devModeAction.title,
                        style: devModeAction.isDestructive ? .destructive : .default
                    ) {
                        devModeAction.perform()
                    }
                }

                if !$0.isEmpty {
                    akActions.append(
                        .init(
                            "Back",
                            style: .cancel
                        ) {
                            DevModeService.presentActionSheet()
                        }
                    )
                }
            }

            await AKActionSheet(
                title: "Developer Mode Options",
                actions: akActions
            ).present(translating: [])
        }
    }

    // MARK: - Toggling

    public static func promptToToggle() {
        Task {
            @Dependency(\.build) var build: Build
            guard build.milestone != .generalRelease else { return }

            guard !build.isDeveloperModeEnabled else {
                let confirmed = await AKConfirmationAlert(
                    title: "Disable Developer Mode",
                    message: "Are you sure you'd like to disable Developer Mode?",
                    confirmButtonTitle: "Disable",
                    confirmButtonStyle: .destructivePreferred
                ).present(translating: [])

                guard confirmed else { return }
                return toggleDeveloperMode(enabled: false)
            }

            let input = await AKTextInputAlert(
                title: "Enable Developer Mode",
                message: "Enter the Developer Mode password to continue.",
                attributes: .init(
                    isSecureTextEntry: true,
                    keyboardType: .numberPad,
                    placeholderText: "••••••"
                ),
                confirmButtonTitle: "Done"
            ).present(translating: [])

            guard let input else { return }
            guard input == build.expirationOverrideCode else {
                return await AKAlert(
                    title: "Enable Developer Mode",
                    message: "The password entered was not correct. Please try again.",
                    actions: [
                        .init("Try Again", style: .preferred) { promptToToggle() },
                        .cancelAction(title: "Cancel"),
                    ]
                ).present(translating: [])
            }

            toggleDeveloperMode(enabled: true)
        }
    }

    // MARK: - Auxiliary

    private static func toggleDeveloperMode(enabled: Bool) {
        @Dependency(\.build) var build: Build
        @Dependency(\.coreKit.hud) var coreHUD: CoreKit.HUD

        build.setIsDeveloperModeEnabled(enabled)
        coreHUD.showSuccess(text: "Developer Mode \(enabled ? "Enabled" : "Disabled")")
    }
}
