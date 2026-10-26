//
//  UserDefaults+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// Convenience methods for reading, writing, and resetting
/// `UserDefaults` using ``PersistentStorageKey`` values.
///
/// - SeeAlso: ``PersistentStorageKey``, ``Persistent``
public extension UserDefaults {
    // MARK: - Types

    /// The strategy that determines which keys are preserved when
    /// resetting persistent storage.
    ///
    /// Use a preservation strategy with ``reset(preserving:)`` to
    /// control which entries survive a reset:
    ///
    /// ```swift
    /// defaults.reset(preserving: .permanentAndSubsystemKeys(plus: [.authToken]))
    /// ```
    enum KeyPreservationStrategy {
        /* MARK: Cases */

        /// Preserve only the specified keys.
        case custom([PersistentStorageKey])

        /// Preserve nothing; all keys are removed.
        case none

        /// Preserve permanent keys registered through the
        /// ``AppSubsystem/Delegates/PermanentPersistentStorageKeyDelegate``,
        /// subsystem keys, and any additional keys you specify.
        case permanentAndSubsystemKeys(plus: [PersistentStorageKey]? = nil)

        /// Preserve subsystem keys and any additional keys you
        /// specify.
        case subsystemKeys(plus: [PersistentStorageKey]? = nil)

        /* MARK: Properties */

        fileprivate var keys: [PersistentStorageKey] {
            switch self {
            case let .custom(keys):
                return keys.unique

            case .none:
                return []

            case let .permanentAndSubsystemKeys(plus: additionalKeys):
                let additionalKeys = additionalKeys ?? []
                let permanentKeys = AppSubsystem.delegates.permanentPersistentStorageKeys?.permanentKeys ?? []
                return (additionalKeys + permanentKeys + PersistentStorageKey.subsystemKeys).unique

            case let .subsystemKeys(plus: additionalKeys):
                return ((additionalKeys ?? []) + PersistentStorageKey.subsystemKeys).unique
            }
        }
    }

    // MARK: - Methods

    /// Removes the value for the given key from both `UserDefaults`
    /// and the Application Support directory.
    ///
    /// If the key has a corresponding file written by
    /// ``Persistent``, that file is also deleted.
    ///
    /// - Parameter defaultName: The key whose value should be removed.
    func removeObject(forKey defaultName: PersistentStorageKey) {
        @Dependency(\.fileManager) var fileManager: FileManager
        removeObject(forKey: defaultName.rawValue)
        try? fileManager.removeItem(
            at: FileManager
                .applicationSupportDirectoryURL
                .appending(path: defaultName.rawValue)
        )
    }

    /// Removes all entries from persistent storage, preserving only
    /// the keys specified by the given strategy.
    ///
    /// This method removes values from both `UserDefaults` and the
    /// Application Support directory, ensuring that filesystem-backed
    /// entries written by ``Persistent`` are also deleted. Values
    /// that ``Persistent`` has cached in memory are discarded.
    ///
    /// The default strategy preserves permanent keys registered
    /// through the
    /// ``AppSubsystem/Delegates/PermanentPersistentStorageKeyDelegate``
    /// and subsystem-internal keys.
    ///
    /// - Important: Every file at the top level of the Application
    ///   Support directory whose name doesn't match a preserved key
    ///   is deleted. Subdirectories are left in place.
    ///
    /// - Parameter preserving: The preservation strategy. The default
    ///   is ``KeyPreservationStrategy/permanentAndSubsystemKeys(plus:)``.
    func reset(preserving: KeyPreservationStrategy = .permanentAndSubsystemKeys()) {
        @Dependency(\.fileManager) var fileManager: FileManager

        let preservedKeys = preserving.keys
        let dictionary = dictionaryRepresentation()
        let preservedValues = preservedKeys.reduce(into: [String: Any]()) { partialResult, key in
            if let value = value(forKey: key.rawValue) {
                partialResult[key.rawValue] = value
            }
        }

        dictionary.keys.forEach { removeObject(forKey: $0) }
        for (key, value) in preservedValues {
            set(value, forKey: key)
        }

        // Values archived by Persistent live only in files
        // named for their keys, so they never appear in the
        // dictionary representation.
        let preservedFileNames = Set(preservedKeys.map(\.rawValue))
        let fileURLs = (try? fileManager.contentsOfDirectory(
            at: FileManager.applicationSupportDirectoryURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: .skipsHiddenFiles
        )) ?? []

        for fileURL in fileURLs where !preservedFileNames.contains(fileURL.lastPathComponent) {
            guard (try? fileURL.resourceValues(
                forKeys: [.isRegularFileKey]
            ))?.isRegularFile == true else { continue }
            try? fileManager.removeItem(at: fileURL)
        }

        PersistenceCache.clearCache()
    }

    /// Sets the value for the given key.
    ///
    /// - Parameters:
    ///   - value: The value to store, or `nil` to remove the entry.
    ///   - defaultName: The key to associate with the value.
    func set(
        _ value: Any?,
        forKey defaultName: PersistentStorageKey
    ) {
        set(value, forKey: defaultName.rawValue)
    }

    /// Returns the value for the given key, or `nil` if no value
    /// exists.
    ///
    /// - Parameter key: The key to look up.
    ///
    /// - Returns: The stored value, or `nil`.
    func value(forKey key: PersistentStorageKey) -> Any? {
        value(forKey: key.rawValue)
    }
}
