//
//  Persistent.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A property wrapper that persists a `Codable` value across launches.
///
/// Use `@Persistent` to bind a property directly to a
/// ``PersistentStorageKey``. The wrapper encodes and decodes values
/// automatically using a binary property list, falling back to JSON
/// when property list coding is not supported. Types that are
/// natively supported by `UserDefaults` (such as `Bool`, `Int`, and
/// `String`) are stored directly:
///
/// ```swift
/// @Persistent(.hasCompletedOnboarding) var hasCompletedOnboarding: Bool?
/// @Persistent(.lastSyncDate) var lastSyncDate: Date?
/// ```
///
/// The wrapped value is always optional. Reading returns `nil` when no
/// value has been stored for the key. Assigning `nil` removes the
/// entry entirely.
///
/// ## Custom Codable Types
///
/// Any type that conforms to `Codable` can be persisted – including
/// your own model types:
///
/// ```swift
/// @Persistent(.userPreferences) var preferences: UserPreferences?
/// ```
///
/// ## Storage Strategy
///
/// Small values are stored in `UserDefaults`. When the encoded
/// representation of a value reaches 16 KB, or the total size of
/// `UserDefaults` reaches 2 MB, the wrapper compresses the data using
/// LZFSE and writes it to a file in the app's Application Support
/// directory instead. This transition is automatic and transparent to
/// the caller – reading and writing through the property wrapper
/// behaves the same regardless of where the value is stored.
///
/// On read, the wrapper resolves values in the following order:
///
/// 1. Encoded `Data` in `UserDefaults`.
/// 2. A natively stored value in `UserDefaults` (for primitive types).
/// 3. A compressed file in the Application Support directory.
///
/// If none of these sources contain a value for the key, the wrapper
/// returns `nil`.
///
/// - Note: `Persistent` is a reference type (`class`) so that it can
///   be used as a local variable inside closures and non-mutating
///   contexts.
///
/// - SeeAlso: ``PersistentStorageKey``
@propertyWrapper
public final class Persistent<T: Codable> {
    // MARK: - Dependencies

    @Dependency(\.userDefaults) private var defaults: UserDefaults
    @Dependency(\.fileManager) private var fileManager: FileManager
    @Dependency(\.jsonDecoder) private var jsonDecoder: JSONDecoder
    @Dependency(\.jsonEncoder) private var jsonEncoder: JSONEncoder
    @Dependency(\.propertyListDecoder) private var propertyListDecoder: PropertyListDecoder
    @Dependency(\.propertyListEncoder) private var propertyListEncoder: PropertyListEncoder

    // MARK: - Properties

    private let key: PersistentStorageKey

    // MARK: - Init

    /// Creates a persistent property bound to the given key.
    ///
    /// - Parameter key: The ``PersistentStorageKey`` that identifies the
    ///   stored value.
    public init(_ key: PersistentStorageKey) {
        self.key = key
    }

    // MARK: - WrappedValue

    /// The persisted value, or `nil` if no value exists for the key.
    ///
    /// On read, the wrapper checks `UserDefaults` first, then falls
    /// back to the Application Support directory. On write, the
    /// wrapper encodes the value and selects the appropriate storage
    /// location automatically.
    public var wrappedValue: T? {
        get { getValue() }
        set { setValue(to: newValue) }
    }

    // MARK: - Auxiliary

    private func getValue() -> T? {
        if let data = defaults.value(forKey: key) as? Data {
            return (try? propertyListDecoder.decode(
                T.self,
                from: data
            )) ?? (try? jsonDecoder.decode(
                T.self,
                from: data
            ))
        } else if let value = defaults.value(forKey: key) as? T {
            return value
        } else if let compressedData = try? Data(contentsOf: FileManager
            .applicationSupportDirectoryURL
            .appending(path: key.rawValue)),
            let decompressedData = try? (compressedData as NSData)
            .decompressed(using: .lzfse) as Data {
            return (try? propertyListDecoder.decode(
                T.self,
                from: decompressedData
            )) ?? (try? jsonDecoder.decode(
                T.self,
                from: decompressedData
            ))
        }

        return nil
    }

    private func removeValue() {
        try? fileManager.removeItem(
            at: FileManager
                .applicationSupportDirectoryURL
                .appending(path: key.rawValue)
        )

        defaults.removeObject(forKey: key)
    }

    private func setValue(to newValue: T?) {
        guard newValue != nil else { return removeValue() }
        removeValue()

        let encodedData = (try? propertyListEncoder.encode(newValue)) ?? (try? jsonEncoder.encode(newValue))
        guard let encodedData else {
            return defaults.set(
                newValue,
                forKey: key
            )
        }

        if encodedData.count >= 16000 ||
            UserDefaults.totalSizeInBytes >= 2_000_000 {
            guard let compressedData = try? (encodedData as NSData)
                .compressed(using: .lzfse) as Data else {
                return defaults.set(
                    encodedData,
                    forKey: key
                )
            }

            try? compressedData.write(
                to: FileManager
                    .applicationSupportDirectoryURL
                    .appending(path: key.rawValue),
                options: [.atomic]
            )
        } else {
            defaults.set(
                encodedData,
                forKey: key
            )
        }
    }
}

private enum PropertyListDecoderDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> PropertyListDecoder {
        .init()
    }
}

private enum PropertyListEncoderDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> PropertyListEncoder {
        let propertyListEncoder = PropertyListEncoder()
        propertyListEncoder.outputFormat = .binary
        return propertyListEncoder
    }
}

private extension DependencyValues {
    var propertyListDecoder: PropertyListDecoder {
        get { self[PropertyListDecoderDependency.self] }
        set { self[PropertyListDecoderDependency.self] = newValue }
    }

    var propertyListEncoder: PropertyListEncoder {
        get { self[PropertyListEncoderDependency.self] }
        set { self[PropertyListEncoderDependency.self] = newValue }
    }
}

private extension UserDefaults {
    static var totalSizeInBytes: Int {
        @Dependency(\.userDefaults) var defaults: UserDefaults
        return (try? PropertyListSerialization.data(
            fromPropertyList: defaults.dictionaryRepresentation(),
            format: .binary,
            options: 0
        ))?.count ?? 0
    }
}
