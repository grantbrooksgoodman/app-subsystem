//
//  UserDefaultsKey.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A strongly typed key for reading and writing values in
/// `UserDefaults`.
///
/// Define your keys as static properties on `UserDefaultsKey` so they
/// can be referenced by the ``Persistent`` property wrapper and the
/// `UserDefaults` convenience methods:
///
/// ```swift
/// extension UserDefaultsKey {
///     static let hasCompletedOnboarding: UserDefaultsKey = .init("hasCompletedOnboarding")
///     static let lastSyncDate: UserDefaultsKey = .init("lastSyncDate")
/// }
/// ```
///
/// Using a dedicated key type prevents raw-string typos and makes it
/// easy to audit every persisted value in the app.
///
/// - SeeAlso: ``Persistent``
public struct UserDefaultsKey: Hashable, Sendable {
    // MARK: - Properties

    let rawValue: String

    // MARK: - Init

    /// Creates a key with the given string identifier.
    ///
    /// - Parameter rawValue: The string to use as the `UserDefaults`
    ///   key.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}
