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

/// The interface for managing and presenting Developer Mode actions at
/// runtime.
///
/// `DevModeService` maintains an ordered list of app-level
/// ``DevModeAction`` values alongside a set of built-in subsystem
/// actions. When the Developer Mode action sheet is presented, the
/// service groups actions into two domains:
///
/// - **Application domain.** Actions registered by the host
///   app, either through the
///   ``AppSubsystem/Delegates/DevModeAppActionDelegate`` at launch or
///   added dynamically at runtime.
/// - **Subsystem domain.** Built-in diagnostic actions provided by
///   AppSubsystem (theme switching, cache clearing, language overrides,
///   and others).
///
/// ## Adding and Removing Actions
///
/// Add actions at any point after initialization:
///
/// ```swift
/// DevModeService.addAction(
///     DevModeAction(title: "Dump Auth Token") {
///         print(AuthService.token ?? "nil")
///     }
/// )
/// ```
///
/// Insert actions at a specific position, or relative to an existing
/// action, to control their order in the menu:
///
/// ```swift
/// DevModeService.insertAction(resetAction, at: 0)
/// DevModeService.insertAction(newAction, after: existingAction)
/// ```
///
/// Remove actions by title or index when they are no longer relevant:
///
/// ```swift
/// DevModeService.removeAction(withTitle: "Dump Auth Token")
/// ```
///
/// ## Presenting the Menu
///
/// Call ``presentActionSheet()`` to show the Developer Mode menu. When
/// app-domain actions are available, the user first chooses
/// between the app and subsystem domains before seeing the
/// individual actions.
///
/// ## Toggling Developer Mode
///
/// Call ``promptToToggle()`` to present a password-protected prompt
/// that enables or disables Developer Mode. Developer Mode is not
/// available on general-release builds.
///
/// - SeeAlso: ``DevModeAction``,
///   ``AppSubsystem/Delegates/DevModeAppActionDelegate``
public enum DevModeService {
    // MARK: - Types

    private enum ActionDomain {
        case application
        case subsystem
    }

    // MARK: - Properties

    private static let appActions = LockIsolated(
        AppSubsystem.delegates.devModeAppActions?.appActions ?? []
    )

    // MARK: - Computed Properties

    private static var subsystemActions: [DevModeAction] {
        DevModeAction.Subsystem.available
    }

    // MARK: - Action Addition

    /// Adds an action to the end of the app-domain list.
    ///
    /// If an action with matching metadata already exists, it is
    /// replaced.
    ///
    /// - Parameter action: The action to add.
    public static func addAction(_ action: DevModeAction) {
        appActions.projectedValue.withValue {
            $0.removeAll(where: { $0.metadata(isEqual: action) })
            $0.append(action)
        }
    }

    /// Adds multiple actions to the end of the app-domain list.
    ///
    /// - Parameter actions: The actions to add.
    public static func addActions(_ actions: [DevModeAction]) {
        actions.forEach { addAction($0) }
    }

    // MARK: - Action Insertion

    /// Inserts an action immediately after an existing action.
    ///
    /// The position is determined by matching the metadata of
    /// `precedingAction`. If no match is found, the action is not
    /// inserted.
    ///
    /// - Parameters:
    ///   - action: The action to insert.
    ///   - precedingAction: The action after which to insert.
    public static func insertAction(
        _ action: DevModeAction,
        after precedingAction: DevModeAction
    ) {
        appActions.projectedValue.withValue {
            guard let index = $0.firstIndex(where: {
                $0.metadata(isEqual: precedingAction)
            }) else { return }

            $0.removeAll(where: { $0.metadata(isEqual: action) })
            $0.insert(action, at: min(index + 1, $0.count))
        }
    }

    /// Inserts an action at the given index in the app-domain
    /// list.
    ///
    /// If an action with matching metadata already exists, it is
    /// removed before the insertion. If the index equals the current
    /// count, the action is appended. Out-of-bounds indices are
    /// ignored.
    ///
    /// - Parameters:
    ///   - action: The action to insert.
    ///   - index: The position at which to insert the action.
    public static func insertAction(
        _ action: DevModeAction,
        at index: Int
    ) {
        appActions.projectedValue.withValue {
            guard index > -1,
                  index <= $0.count else { return }

            $0.removeAll(where: { $0.metadata(isEqual: action) })
            $0.insert(action, at: min(index, $0.count))
        }
    }

    /// Inserts multiple actions starting at the given index.
    ///
    /// The actions appear in the order provided, beginning at `index`.
    ///
    /// - Parameters:
    ///   - actions: The actions to insert.
    ///   - index: The position at which to begin inserting.
    public static func insertActions(
        _ actions: [DevModeAction],
        at index: Int
    ) {
        actions.reversed().forEach { insertAction($0, at: index) }
    }

    /// Inserts an action immediately before an existing action.
    ///
    /// The position is determined by matching the metadata of
    /// `succeedingAction`. If no match is found, the action is not
    /// inserted.
    ///
    /// - Parameters:
    ///   - action: The action to insert.
    ///   - succeedingAction: The action before which to insert.
    public static func insertAction(
        _ action: DevModeAction,
        before succeedingAction: DevModeAction
    ) {
        appActions.projectedValue.withValue {
            guard let index = $0.firstIndex(where: {
                $0.metadata(isEqual: succeedingAction)
            }) else { return }

            $0.removeAll(where: { $0.metadata(isEqual: action) })
            $0.insert(action, at: min(index, $0.count))
        }
    }

    // MARK: - Action Removal

    /// Removes the action at the given index from the
    /// app-domain list.
    ///
    /// Out-of-bounds indices are ignored.
    ///
    /// - Parameter index: The position of the action to remove.
    public static func removeAction(at index: Int) {
        appActions.projectedValue.withValue {
            guard index < $0.count,
                  index > -1 else { return }

            $0.remove(at: index)
        }
    }

    /// Removes all actions with the given title from the
    /// app-domain list.
    ///
    /// - Parameter withTitle: The title of the action to remove.
    public static func removeAction(withTitle: String) {
        appActions.projectedValue.withValue {
            guard $0.contains(where: { $0.title == withTitle }) else { return }
            $0.removeAll(where: { $0.title == withTitle })
        }
    }

    // MARK: - Menu Presentation

    /// Presents the Developer Mode action sheet.
    ///
    /// When the app-domain list contains actions, the sheet
    /// first offers a choice between the app and subsystem
    /// domains. When the list is empty, the subsystem-domain actions
    /// are shown directly.
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

    /// Presents a password-protected prompt to enable or disable
    /// Developer Mode.
    ///
    /// When Developer Mode is currently disabled, the user is asked to
    /// enter the build's expiration override code. When it is already
    /// enabled, a destructive confirmation alert is shown instead.
    ///
    /// This method has no effect on general-release builds.
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
