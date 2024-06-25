//
//  DependencyValues.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public struct DependencyValues: Sendable {
    // MARK: - Properties

    @TaskLocal static var current = Self()

    private var resolverCache = ResolverCache()
    private var storage = [ObjectIdentifier: any Sendable]()

    // MARK: - Subscript

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

    private var cache = [ObjectIdentifier: any Sendable]()
    private var lock = NSRecursiveLock()

    // MARK: - Methods

    public func value<Key: DependencyKey>(for key: Key.Type, dependencies: DependencyValues) -> Key.Value {
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
