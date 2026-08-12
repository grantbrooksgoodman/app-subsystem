//
//  ForcedUpdateModalDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension AppSubsystem.Delegates {
    /// A type that configures the full-screen modal requiring the
    /// user to update the app.
    ///
    /// When a newer version of the app is required – for
    /// example, because the server no longer supports the running
    /// version – the subsystem can present an undismissable modal
    /// that prompts the user to install the update. Conform to this
    /// protocol to control where the install button redirects the
    /// user:
    ///
    /// ```swift
    /// struct AppForcedUpdateModal: AppSubsystem.Delegates.ForcedUpdateModalDelegate {
    ///     let installButtonRedirectURL: URL? = URL(
    ///         string: "https://apps.apple.com/app/id1234567890"
    ///     )
    /// }
    /// ```
    ///
    /// To trigger presentation of the modal, set the
    /// ``SharedStates/isForcedUpdateRequired`` shared state to
    /// `true`. The subsystem observes this value and presents the
    /// modal on its first `true` emission.
    protocol ForcedUpdateModalDelegate {
        /// The URL to open when the user taps the install button, or
        /// `nil` if no redirect is configured.
        ///
        /// Typically, this points to the app's App Store
        /// listing.
        var installButtonRedirectURL: URL? { get }
    }
}
