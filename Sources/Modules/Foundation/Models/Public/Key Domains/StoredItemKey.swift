//
//  StoredItemKey.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A strongly typed key for storing and retrieving values in
/// ``RuntimeStorage``.
///
/// Define app-specific keys as static properties in an
/// extension:
///
/// ```swift
/// extension StoredItemKey {
///     static let currentUser: StoredItemKey = .init("currentUser")
///     static let sessionToken: StoredItemKey = .init("sessionToken")
/// }
/// ```
///
/// Pass these keys to ``RuntimeStorage/store(_:as:)``,
/// ``RuntimeStorage/retrieve(_:)``, and
/// ``RuntimeStorage/remove(_:)`` to access the corresponding
/// values.
///
/// - SeeAlso: ``RuntimeStorage``
public struct StoredItemKey: Hashable, Sendable {
    // MARK: - Properties

    let rawValue: String

    // MARK: - Init

    /// Creates a stored-item key with the given identifier.
    ///
    /// - Parameter rawValue: A string that uniquely names the stored
    ///   item (for example, `"currentUser"`).
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}
