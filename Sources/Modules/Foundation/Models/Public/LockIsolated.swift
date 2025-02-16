//
//  LockIsolated.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

@propertyWrapper
public final class LockIsolated<Value>: @unchecked Sendable {
    // MARK: - Properties

    private var isolatedValue: _LockIsolated<Value>

    // MARK: - Init

    public init(wrappedValue: @autoclosure @Sendable () -> Value) {
        isolatedValue = _LockIsolated(wrappedValue())
    }

    // MARK: - WrappedValue

    public var wrappedValue: Value {
        get { isolatedValue.value }
        set { isolatedValue.setValue(newValue) }
    }
}

@dynamicMemberLookup
private final class _LockIsolated<Value>: @unchecked Sendable {
    // MARK: - Properties

    private let lock = NSRecursiveLock()
    private var _value: Value

    // MARK: - Init

    init(_ value: @autoclosure @Sendable () throws -> Value) rethrows {
        _value = try value()
    }

    // MARK: - Subscript

    subscript<Subject: Sendable>(dynamicMember keyPath: KeyPath<Value, Subject>) -> Subject {
        lock.sync { _value[keyPath: keyPath] }
    }

    // MARK: - Auxiliary

    func setValue(_ newValue: @autoclosure @Sendable () throws -> Value) rethrows {
        try lock.sync { _value = try newValue() }
    }

    func withValue<T: Sendable>(
        _ operation: @Sendable (inout Value) throws -> T
    ) rethrows -> T {
        try self.lock.sync {
            var value = _value
            defer { _value = value }
            return try operation(&value)
        }
    }
}

public extension NSRecursiveLock {
    @inlinable @discardableResult
    @_spi(Internals) func sync<R>(work: () throws -> R) rethrows -> R {
        lock()
        defer { unlock() }
        return try work()
    }
}

extension _LockIsolated where Value: Sendable {
    var value: Value {
        lock.sync { _value }
    }
}

#if swift(<6)
@available(*, deprecated, message: "Lock isolated values should not be equatable")
extension _LockIsolated: Equatable where Value: Equatable {
    static func == (left: _LockIsolated, right: _LockIsolated) -> Bool {
        left.value == right.value
    }
}

@available(*, deprecated, message: "Lock isolated values should not be hashable")
extension _LockIsolated: Hashable where Value: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}
#endif
