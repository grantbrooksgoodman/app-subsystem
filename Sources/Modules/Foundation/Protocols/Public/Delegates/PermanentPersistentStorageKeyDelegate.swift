//
//  PermanentPersistentStorageKeyDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension AppSubsystem.Delegates {
    /// A type that declares which persistent storage keys should
    /// survive a reset.
    ///
    /// Conform to `PermanentPersistentStorageKeyDelegate` and return
    /// the keys your app must preserve across calls to
    /// `UserDefaults.reset(preserving:)`:
    ///
    /// ```swift
    /// struct MyPermanentKeys: AppSubsystem.Delegates.PermanentPersistentStorageKeyDelegate {
    ///     var permanentKeys: [PersistentStorageKey] {
    ///         [.authToken, .installationID]
    ///     }
    /// }
    /// ```
    ///
    /// Pass the conforming instance to ``AppSubsystem`` during
    /// initialization.
    ///
    /// - SeeAlso: ``PersistentStorageKey``,
    ///   ``UserDefaults/KeyPreservationStrategy``
    protocol PermanentPersistentStorageKeyDelegate {
        /// The keys that should be preserved during a persistent
        /// storage reset.
        var permanentKeys: [PersistentStorageKey] { get }
    }
}
