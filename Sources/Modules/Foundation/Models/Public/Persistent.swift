//
//  Persistent.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A property wrapper that reads and writes a `Codable` value to
/// `UserDefaults`.
///
/// Use `@Persistent` to bind a property directly to a
/// ``UserDefaultsKey``. The wrapper handles JSON encoding and decoding
/// automatically, falling back to direct `UserDefaults` storage for
/// types that are natively supported (such as `Bool`, `Int`, and
/// `String`):
///
/// ```swift
/// @Persistent(.hasCompletedOnboarding) var hasCompletedOnboarding: Bool?
/// @Persistent(.lastSyncDate) var lastSyncDate: Date?
/// ```
///
/// The wrapped value is always optional. Reading returns `nil` when no
/// value has been stored for the key. Assigning `nil` removes the
/// entry from `UserDefaults`.
///
/// ## Custom Codable Types
///
/// Because the wrapper encodes values as JSON `Data`, any type that
/// conforms to `Codable` can be persisted – including your own model
/// types:
///
/// ```swift
/// @Persistent(.userPreferences) var preferences: UserPreferences?
/// ```
///
/// - Note: `Persistent` is a reference type (`class`) so that it can
///   be used as a local variable inside closures and non-mutating
///   contexts.
///
/// - SeeAlso: ``UserDefaultsKey``
@propertyWrapper
public final class Persistent<T: Codable> {
    // MARK: - Dependencies

    @Dependency(\.userDefaults) private var defaults: UserDefaults
    @Dependency(\.jsonDecoder) private var jsonDecoder: JSONDecoder
    @Dependency(\.jsonEncoder) private var jsonEncoder: JSONEncoder

    // MARK: - Properties

    private let key: UserDefaultsKey

    // MARK: - Init

    /// Creates a persistent property bound to the given key.
    ///
    /// - Parameter key: The ``UserDefaultsKey`` that identifies the
    ///   stored value.
    public init(_ key: UserDefaultsKey) {
        self.key = key
    }

    // MARK: - WrappedValue

    /// The persisted value, or `nil` if no value exists for the key.
    ///
    /// On read, the wrapper first attempts to decode the stored
    /// `Data` as the generic type `T`. If decoding fails, it falls
    /// back to reading the value directly from `UserDefaults`.
    ///
    /// On write, the wrapper attempts to JSON-encode the value before
    /// storing it. If encoding fails, the value is stored directly.
    public var wrappedValue: T? {
        get {
            guard let data = defaults.value(forKey: key) as? Data,
                  let decoded: T = try? jsonDecoder.decode(T.self, from: data) else {
                return defaults.value(forKey: key) as? T
            }

            return decoded
        }
        set {
            guard let encoded = try? jsonEncoder.encode(newValue) else {
                defaults.set(newValue, forKey: key)
                return
            }

            defaults.set(encoded, forKey: key)
        }
    }
}
