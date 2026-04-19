//
//  PermanentUserDefaultsKeyDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension AppSubsystem.Delegates {
    /// A type that declares which `UserDefaults` keys should survive a
    /// reset.
    ///
    /// Conform to `PermanentUserDefaultsKeyDelegate` and return the
    /// keys your app must preserve across calls to
    /// `UserDefaults.reset(preserving:)`:
    ///
    /// ```swift
    /// struct MyPermanentKeys: AppSubsystem.Delegates.PermanentUserDefaultsKeyDelegate {
    ///     var permanentKeys: [UserDefaultsKey] {
    ///         [.authToken, .installationID]
    ///     }
    /// }
    /// ```
    ///
    /// Pass the conforming instance to ``AppSubsystem`` during
    /// initialization.
    ///
    /// - SeeAlso: ``UserDefaultsKey``,
    ///   ``UserDefaults/KeyPreservationStrategy``
    protocol PermanentUserDefaultsKeyDelegate {
        /// The keys that should be preserved during a `UserDefaults`
        /// reset.
        var permanentKeys: [UserDefaultsKey] { get }
    }
}
