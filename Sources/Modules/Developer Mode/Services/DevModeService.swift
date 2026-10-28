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
/// actions. When the Developer Mode menu is presented, the service
/// groups actions into two domains:
///
/// - **Application domain.** Actions supplied by the host app through
///   the ``AppSubsystem/Delegates/DevModeAppActionDelegate``, read each
///   time the menu is presented or refreshed, followed by any actions
///   added at runtime.
/// - **Subsystem domain.** Built-in diagnostic actions provided by
///   AppSubsystem (theme switching, cache clearing, language overrides,
///   and others).
///
/// ## Adding and Removing Actions
///
/// Add actions at any point after initialization. Actions added this
/// way form the runtime list, which follows the delegate's actions in
/// the app domain. The methods below never affect delegate-supplied
/// actions:
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
/// Call ``presentMenu()`` to show the Developer Mode menu as a sheet
/// from the root view. Each domain's actions are listed in their own
/// group, with app-domain actions above subsystem-domain actions.
/// Selecting an action performs it and refreshes the menu, which
/// stays presented until the user dismisses it. Call ``refreshMenu()``
/// from an action whose state changes after it performs.
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
    // MARK: - Properties

    private static let runtimeActions = LockIsolated([DevModeAction]())

    // MARK: - Computed Properties

    @MainActor
    static var appDomainActions: [DevModeAction] {
        (AppSubsystem.delegates.devModeAppActions?.appActions ?? []) + runtimeActions.wrappedValue
    }

    @MainActor
    static var subsystemDomainActions: [DevModeAction] {
        DevModeAction.Subsystem.available
    }

    // MARK: - Action Addition

    /// Adds an action to the end of the runtime list.
    ///
    /// If an action with matching metadata already exists, it is
    /// replaced.
    ///
    /// - Parameter action: The action to add.
    public static func addAction(_ action: DevModeAction) {
        runtimeActions.projectedValue.withValue {
            $0.removeAll(where: { $0.metadata(isEqual: action) })
            $0.append(action)
        }
    }

    /// Adds multiple actions to the end of the runtime list.
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
        runtimeActions.projectedValue.withValue {
            guard let index = $0.firstIndex(where: {
                $0.metadata(isEqual: precedingAction)
            }) else { return }

            $0.removeAll(where: { $0.metadata(isEqual: action) })
            $0.insert(action, at: min(index + 1, $0.count))
        }
    }

    /// Inserts an action at the given index in the runtime list.
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
        runtimeActions.projectedValue.withValue {
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
        runtimeActions.projectedValue.withValue {
            guard let index = $0.firstIndex(where: {
                $0.metadata(isEqual: succeedingAction)
            }) else { return }

            $0.removeAll(where: { $0.metadata(isEqual: action) })
            $0.insert(action, at: min(index, $0.count))
        }
    }

    // MARK: - Action Removal

    /// Removes the action at the given index from the runtime
    /// list.
    ///
    /// Out-of-bounds indices are ignored.
    ///
    /// - Parameter index: The position of the action to remove.
    public static func removeAction(at index: Int) {
        runtimeActions.projectedValue.withValue {
            guard index < $0.count,
                  index > -1 else { return }

            $0.remove(at: index)
        }
    }

    /// Removes all actions with the given title from the runtime
    /// list.
    ///
    /// - Parameter withTitle: The title of the action to remove.
    public static func removeAction(withTitle: String) {
        runtimeActions.projectedValue.withValue {
            guard $0.contains(where: { $0.title == withTitle }) else { return }
            $0.removeAll(where: { $0.title == withTitle })
        }
    }

    // MARK: - Menu Presentation

    /// Presents the Developer Mode menu as a sheet from the root view.
    ///
    /// The menu lists each domain's actions in a separate group, with
    /// app-domain actions above subsystem-domain actions, followed by
    /// an option to disable Developer Mode. The app-domain group is
    /// omitted when the app domain has no actions. Selecting an action
    /// performs it and refreshes the menu, which stays presented until
    /// the user dismisses it or chooses to disable Developer Mode.
    ///
    /// This method has no effect while an alert controller is presented.
    public static func presentMenu() {
        Task { @MainActor in
            @Dependency(\.uiApplication) var uiApplication: UIApplication
            guard !uiApplication.isPresentingAlertController else { return }

            RootSheets.dismiss()
            RootSheets.present(.init(.init(
                DevModeMenuView(
                    .init(
                        initialState: .init(),
                        reducer: DevModeMenuReducer()
                    )
                )
            )))
        }
    }

    // MARK: - Menu Refresh

    /// Refreshes the Developer Mode menu, if it is presented.
    ///
    /// The menu refreshes automatically after each action performs
    /// and whenever an alert controller is dismissed. Call this method
    /// from an action whose state changes later – for example, after
    /// asynchronous work completes – so that the menu's titles and
    /// switch states reflect the latest values.
    public static func refreshMenu() {
        SharedEvent(\.devModeMenuRefreshRequested).wrappedValue.send()
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
