//
//  ForcedUpdateModalDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Combine
import Foundation

public extension AppSubsystem.Delegates {
    /// A type that drives the presentation of a full-screen modal
    /// requiring the user to update the app.
    ///
    /// When a newer version of the app is required – for
    /// example, because the server no longer supports the running
    /// version – the subsystem can present an undismissable modal
    /// that prompts the user to install the update. Conform to this
    /// protocol to control when this modal appears and where the
    /// install button redirects the user.
    ///
    /// Publish `true` to ``isForcedUpdateRequiredSubject`` when an
    /// update is required. The subsystem observes this subject and
    /// presents the modal automatically on the first `true` emission:
    ///
    /// ```swift
    /// struct AppForcedUpdateModal: AppSubsystem.Delegates.ForcedUpdateModalDelegate {
    ///     let installButtonRedirectURL: URL? = URL(
    ///         string: "https://apps.apple.com/app/id1234567890"
    ///     )
    ///     let isForcedUpdateRequiredSubject = CurrentValueSubject<Bool?, Never>(nil)
    /// }
    /// ```
    ///
    /// - Note: The initial value of the subject should be `nil`,
    ///   indicating that the update requirement has not yet been
    ///   determined. The subsystem ignores `nil` values and only
    ///   reacts to non-`nil` Boolean emissions.
    protocol ForcedUpdateModalDelegate {
        /// The URL to open when the user taps the install button, or
        /// `nil` if no redirect is configured.
        ///
        /// Typically, this points to the app's App Store
        /// listing.
        var installButtonRedirectURL: URL? { get }

        /// A subject that publishes whether a forced update is
        /// required.
        ///
        /// Send `true` to trigger presentation of the forced-update
        /// modal. Send `false` or `nil` to indicate that no update
        /// is required. The subsystem observes this subject using
        /// ``forcedUpdateRequiredPublisher`` and presents the modal
        /// on the first `true` emission.
        var isForcedUpdateRequiredSubject: CurrentValueSubject<Bool?, Never> { get }
    }
}

public extension AppSubsystem.Delegates.ForcedUpdateModalDelegate {
    /// A publisher that emits `true` the first time a forced update
    /// is required.
    ///
    /// This publisher filters out `nil` values from
    /// ``isForcedUpdateRequiredSubject``, removes consecutive
    /// duplicates, and is used by the subsystem to observe update
    /// status changes.
    var forcedUpdateRequiredPublisher: AnyPublisher<Bool, Never> {
        isForcedUpdateRequiredSubject
            .receive(on: DispatchQueue.main)
            .compactMap(\.self)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
