//
//  PersistentStorageKey.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A strongly typed key for identifying values in persistent storage.
///
/// Define your keys as static properties on `PersistentStorageKey` so
/// they can be referenced by the ``Persistent`` property wrapper and
/// the `UserDefaults` convenience methods:
///
/// ```swift
/// extension PersistentStorageKey {
///     static let hasCompletedOnboarding: PersistentStorageKey = .init("hasCompletedOnboarding")
///     static let lastSyncDate: PersistentStorageKey = .init("lastSyncDate")
/// }
/// ```
///
/// Using a dedicated key type prevents raw-string typos and makes it
/// easy to audit every persisted value in the app.
///
/// - SeeAlso: ``Persistent``
public struct PersistentStorageKey: Hashable, Sendable {
    // MARK: - Properties

    let rawValue: String

    // MARK: - Init

    /// Creates a key with the given string identifier.
    ///
    /// - Parameter rawValue: The string that identifies the stored
    ///   value.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}
