//
//  DependencyValues.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// The container that holds every registered dependency in the current
/// scope.
///
/// `DependencyValues` is the central registry for the dependency
/// injection system. Each dependency is accessed through a subscript
/// keyed by its ``DependencyKey`` type:
///
/// ```swift
/// let defaults = DependencyValues.current[UserDefaultsDependency.self]
/// ```
///
/// In practice, you rarely use the subscript directly. Instead, define a
/// convenience property on `DependencyValues` and access it through the
/// ``Dependency`` property wrapper:
///
/// ```swift
/// extension DependencyValues {
///     var userDefaults: UserDefaults {
///         get { self[UserDefaultsDependency.self] }
///         set { self[UserDefaultsDependency.self] = newValue }
///     }
/// }
///
/// // In a reducer or service:
/// @Dependency(\.userDefaults) var userDefaults: UserDefaults
/// ```
///
/// ## Scoping
///
/// The ``current`` value is stored as a `@TaskLocal`, which means each
/// structured-concurrency task inherits the dependency values of its
/// parent. Use ``DependencyScopes/withDependencies(_:operation:)``
/// to override individual dependencies for the duration of a closure.
///
/// ## Resolution and Caching
///
/// When a dependency is accessed for the first time in a given scope,
/// the system calls the key's ``DependencyKey/resolve(_:)`` method and
/// caches the result. Subsequent accesses within the same scope return
/// the cached value without calling `resolve` again.
///
/// - SeeAlso: ``DependencyKey``, ``Dependency``,
///   ``DependencyScopes``
public struct DependencyValues: @unchecked Sendable {
    // MARK: - Properties

    /// The dependency values for the current scope.
    ///
    /// This value is propagated automatically through Swift's structured
    /// concurrency via `@TaskLocal`. Override it for a specific scope
    /// using ``DependencyScopes/withDependencies(_:operation:)``.
    @TaskLocal
    static var current = Self()

    private var resolverCache = ResolverCache()
    private var storage = [ObjectIdentifier: Any]()

    // MARK: - Subscript

    /// Accesses the dependency value associated with the given key type.
    ///
    /// When reading, the subscript first checks for an explicit override
    /// in the current scope. If none is found, it falls back to the
    /// cached result of the key's ``DependencyKey/resolve(_:)`` method.
    ///
    /// When writing, the subscript stores the value as a scope-local
    /// override.
    public subscript<Key: DependencyKey>(key: Key.Type) -> Key.Value {
        get {
            if let value = storage[.identifier(for: key)] as? Key.Value {
                return value
            }

            return resolverCache.value(for: key, dependencies: self)
        }

        set { storage[.identifier(for: key)] = newValue }
    }

    // MARK: - Merging

    func merging(_ other: Self) -> Self {
        var values = self
        values.storage.merge(other.storage, uniquingKeysWith: { $1 })
        return values
    }
}

extension DependencyValues {
    init<Key: DependencyKey>(key: Key.Type, value: Key.Value) {
        var dependencies = DependencyValues()
        dependencies[key] = value
        self = dependencies
    }
}

private final class ResolverCache: @unchecked Sendable {
    // MARK: - Properties

    private var cache = [ObjectIdentifier: Any]()
    private var lock = NSRecursiveLock()

    // MARK: - Methods

    func value<Key: DependencyKey>(for key: Key.Type, dependencies: DependencyValues) -> Key.Value {
        lock.lock()
        defer { lock.unlock() }

        if let value = cache[.identifier(for: key)] as? Key.Value {
            return value
        }

        let value = Key.resolve(dependencies)
        cache[.identifier(for: key)] = value

        return value
    }
}

private extension ObjectIdentifier {
    static func identifier(for type: (some DependencyKey).Type) -> Self { Self(type) }
}
