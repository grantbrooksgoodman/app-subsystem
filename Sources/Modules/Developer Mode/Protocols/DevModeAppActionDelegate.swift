//
//  DevModeAppActionDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension AppSubsystem.Delegates {
    /// A type that supplies app-specific actions to the
    /// Developer Mode menu.
    ///
    /// Conform to `DevModeAppActionDelegate` and return the actions
    /// your app needs in ``appActions``. The subsystem reads these
    /// actions each time the Developer Mode menu is presented or
    /// refreshed, so the list can reflect the app's current state.
    ///
    /// ```swift
    /// struct MyDevModeActions: AppSubsystem.Delegates.DevModeAppActionDelegate {
    ///     var appActions: [DevModeAction] {
    ///         [
    ///             DevModeAction(title: "Log Current User") {
    ///                 print(AuthService.currentUser ?? "none")
    ///             },
    ///         ]
    ///     }
    /// }
    /// ```
    ///
    /// Pass the conforming instance to ``AppSubsystem`` during
    /// initialization so that it is available when the Developer Mode
    /// menu opens. Because the list is read on each presentation and
    /// refresh, it can omit actions that do not apply to the current
    /// state and supply the current state for switch-style actions.
    ///
    /// - SeeAlso: ``DevModeAction``, ``DevModeService``
    protocol DevModeAppActionDelegate {
        /// The actions to display in the app domain of the
        /// Developer Mode menu.
        ///
        /// The subsystem reads this property each time the menu is
        /// presented or refreshed.
        @MainActor
        var appActions: [DevModeAction] { get }
    }
}
