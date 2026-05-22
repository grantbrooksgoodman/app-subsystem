//
//  RuntimeStorage.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A thread-safe, in-memory key-value store for data that should
/// persist for the lifetime of the current launch, but not across
/// launches.
///
/// Use `RuntimeStorage` to share transient state – such as a session
/// token or a resolved configuration value – between otherwise
/// unrelated parts of the app. Values are stored by
/// ``StoredItemKey`` and are accessible from any thread:
///
/// ```swift
/// // Store a value:
/// RuntimeStorage.store(session, as: .currentSession)
///
/// // Retrieve it later:
/// if let session = RuntimeStorage.retrieve(.currentSession) as? Session {
///     // ...
/// }
///
/// // Remove it when no longer needed:
/// RuntimeStorage.remove(.currentSession)
/// ```
///
/// All access is synchronized using a lock, so reads and writes are
/// safe to perform concurrently.
///
/// - Note: `RuntimeStorage` is not a substitute for persistent
///   storage. Values are discarded when the process terminates. For
///   data that must survive across launches, use ``Persistent`` or
///   `UserDefaults` directly.
///
/// - SeeAlso: ``StoredItemKey``
public enum RuntimeStorage {
    // MARK: - Properties

    private static let storedItems = LockIsolated([String: Any]())

    // MARK: - Removal

    /// Removes the value associated with the given key.
    ///
    /// If no value is stored for the key, this method has no effect.
    ///
    /// - Parameter item: The key whose value should be removed.
    public static func remove(_ item: StoredItemKey) {
        storedItems.projectedValue[item.rawValue] = nil
    }

    // MARK: - Retrieval

    /// Returns the value associated with the given key, or `nil` if
    /// no value is stored.
    ///
    /// The returned value is untyped. Cast it to the expected type
    /// at the call site.
    ///
    /// - Parameter item: The key to look up.
    ///
    /// - Returns: The stored value, or `nil` if the key is not
    ///   present.
    public static func retrieve(_ item: StoredItemKey) -> Any? {
        storedItems.projectedValue[item.rawValue]
    }

    // MARK: - Storage

    /// Stores a value under the given key, replacing any existing
    /// value.
    ///
    /// - Parameters:
    ///   - object: The value to store.
    ///   - item: The key to associate with the value.
    public static func store(
        _ object: Any,
        as item: StoredItemKey
    ) {
        storedItems.projectedValue[item.rawValue] = object
    }
}

public extension RuntimeStorage {
    // MARK: - Properties

    /// The active language code for the current session.
    ///
    /// Returns the overridden language code if one has been stored,
    /// the explicitly stored language code if available, or the
    /// system language code as a fallback.
    static var languageCode: String {
        getLanguageCode()
    }

    /// The language-code dictionary for the current session, or
    /// `nil` if none has been stored.
    static var languageCodeDictionary: [String: String]? {
        getLanguageCodeDictionary()
    }

    // MARK: - Functions

    private static func getLanguageCode() -> String {
        guard let overridden = retrieve(.overriddenLanguageCode) as? String else { return retrieve(.languageCode) as? String ?? Locale.systemLanguageCode }
        return overridden
    }

    private static func getLanguageCodeDictionary() -> [String: String]? {
        retrieve(.languageCodeDictionary) as? [String: String]
    }
}
