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
    /// your app needs in ``appActions``. The subsystem
    /// automatically loads these actions when the Developer Mode
    /// action sheet is presented.
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
    /// menu opens.
    ///
    /// - SeeAlso: ``DevModeAction``, ``DevModeService``
    protocol DevModeAppActionDelegate {
        /// The actions to display in the app domain of the
        /// Developer Mode menu.
        var appActions: [DevModeAction] { get }
    }
}
