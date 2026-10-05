//
//  LockIsolated.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A property wrapper that synchronizes access to a value using a lock.
///
/// Use ``LockIsolated`` to protect mutable state that may be accessed from
/// multiple threads. The wrapper provides two access patterns:
///
/// - Use the wrapped value for whole-value reads and writes.
/// - Use the projected value (`$`) for fine-grained operations on the wrapped value.
///
/// For example, use the wrapped value to read or replace the entire value:
///
/// ```swift
/// @LockIsolated var cache = [String: String]()
///
/// let snapshot = cache
/// cache = [:]
/// ```
///
/// Use the projected value to perform an operation on part of the wrapped value,
/// such as reading or writing a single dictionary entry:
///
/// ```swift
/// $cache["greeting"] = "Hello"
/// let greeting = $cache["greeting"]
/// ```
///
/// Use ``LockIsolatedProjection/withValue(_:)`` when an operation must read and
/// modify the value as a single isolated step:
///
/// ```swift
/// $cache.withValue {
///    if $0["greeting"] == nil {
///        $0["greeting"] = "Hello"
///    }
/// }
/// ```
///
/// ## Choosing an access pattern
///
/// Choose the access pattern that matches the operation you want to perform:
///
/// - Use the wrapped value when you need a snapshot of the entire value or when
///   you want to replace the entire value.
/// - Use the projected value when you want to access or mutate a portion of the
///   value, such as an element in a collection.
/// - Use ``LockIsolatedProjection/withValue(_:)`` when the operation must be
///   atomic with respect to the wrapped value.
///
/// For collection types, prefer the projected value for element-level access.
/// Accessing a collection through the wrapped value produces a snapshot of the
/// collection. Mutating that snapshot is distinct from mutating the isolated
/// storage.
///
/// ## Sendability
///
/// ``LockIsolated`` is `Sendable` only when `Value` is `Sendable`. The lock
/// serializes access to the stored value, but it cannot make a non-`Sendable`
/// value safe to share: a reference type handed out through the wrapped value or
/// ``LockIsolatedProjection/withValue(_:)`` leaves the lock behind and is used
/// unsynchronized by whoever receives it.
///
/// When a non-`Sendable` value genuinely must be guarded across isolation
/// domains, use ``UncheckedLockIsolated``. It offers the same API and states the
/// unverified claim at the declaration site. To move a non-`Sendable` value
/// across a boundary without a lock – for example, to capture a dependency in a
/// `@Sendable` closure – use ``UncheckedSendable`` instead.
///
/// ## Discussion
///
/// ``LockIsolated`` isolates individual accesses to the wrapped value. For
/// compound operations that depend on the current value, use the projected value’s
/// ``LockIsolatedProjection/withValue(_:)`` method to ensure the operation
/// observes and mutates a single consistent value.
///
/// The wrapped value remains useful for coarse-grained operations, such as
/// replacing the entire value or reading a snapshot for later use.
///
/// - Warning: ``LockIsolated`` synchronizes individual accesses to its stored
///   value, but it does not make all uses of that value automatically atomic or
///   independent.
///
///   Keep these pitfalls in mind:
///
///   - Reading the wrapped value produces a snapshot of the current value.
///     Subsequent mutations to that snapshot are not synchronized with the
///     isolated storage.
///
///   - Compound operations are not atomic when performed through separate reads
///     and writes of the wrapped value. Use
///     ``LockIsolatedProjection/withValue(_:)`` when an operation must observe
///     and mutate the value as one isolated step.
///
///   - When the wrapped value is a reference type, ``LockIsolated`` protects
///     access to the stored reference, not arbitrary mutation of the referenced
///     object after it has escaped. Prefer value-semantic types when possible.
///
///   - Because ``LockIsolated`` is a reference type, storing it in a value type
///     such as a struct introduces shared storage. Copying the enclosing value
///     copies the wrapper reference rather than creating an independent isolated
///     value.
///
///   - Avoid performing long-running work or calling out to unknown code from
///     within ``LockIsolatedProjection/withValue(_:)``. Keep isolated operations
///     small and focused.
@propertyWrapper
public final class LockIsolated<Value> {
    // MARK: - Properties

    private let isolatedValue: _LockIsolated<Value>

    // MARK: - Init

    public init(wrappedValue: @autoclosure () -> Value) {
        isolatedValue = _LockIsolated(wrappedValue())
    }

    public convenience init(_ wrappedValue: @autoclosure () -> Value) {
        self.init(wrappedValue: wrappedValue())
    }

    // MARK: - Projected Value

    public var projectedValue: LockIsolatedProjection<Value> { .init(isolatedValue) }

    // MARK: - Wrapped Value

    public var wrappedValue: Value {
        get { isolatedValue.value }
        set { isolatedValue.setValue(newValue) }
    }
}

/// Lock-isolated storage for a value that is not `Sendable`.
///
/// `UncheckedLockIsolated` behaves identically to ``LockIsolated`` – the same
/// wrapped value, projected value, and ``LockIsolatedProjection/withValue(_:)``
/// semantics – but is `Sendable` regardless of `Value`. The compiler cannot
/// verify that the stored value is safe to share across isolation domains; that
/// guarantee is yours.
///
/// Use it only when both of the following hold:
///
/// - The value cannot reasonably be made `Sendable` – a system object with no
///   `Sendable` annotation, a dictionary of plain closures, or an `Any`-typed
///   payload.
/// - The lock is genuinely needed, because the value is read or mutated from
///   more than one context.
///
/// If the value is `Sendable`, use ``LockIsolated``. If the value only needs to
/// cross a boundary once and is never shared afterward, use
/// ``UncheckedSendable``, which carries no lock.
///
/// ```swift
/// @UncheckedLockIsolated private var effects = [EffectID: () -> Void]()
/// ```
@propertyWrapper
public final class UncheckedLockIsolated<Value>: @unchecked Sendable {
    // MARK: - Properties

    private let base: LockIsolated<Value>

    // MARK: - Init

    public init(
        wrappedValue: @autoclosure () -> Value
    ) {
        base = LockIsolated(wrappedValue: wrappedValue())
    }

    public convenience init(
        _ wrappedValue: @autoclosure () -> Value
    ) {
        self.init(wrappedValue: wrappedValue())
    }

    // MARK: - Projected Value

    public var projectedValue: LockIsolatedProjection<Value> { base.projectedValue }

    // MARK: - Wrapped Value

    public var wrappedValue: Value {
        get { base.wrappedValue }
        set { base.wrappedValue = newValue }
    }
}

@dynamicMemberLookup
public struct LockIsolatedProjection<Value> {
    // MARK: - Properties

    private let isolatedValue: _LockIsolated<Value>

    // MARK: - Init

    fileprivate init(_ isolatedValue: _LockIsolated<Value>) {
        self.isolatedValue = isolatedValue
    }

    // MARK: - Atomic Access

    @discardableResult
    public func withValue<T>(
        _ operation: (inout Value) throws -> T
    ) rethrows -> T {
        try isolatedValue.withValue(operation)
    }

    // MARK: - Dynamic Member Lookup

    public subscript<Subject>(
        dynamicMember keyPath: KeyPath<Value, Subject>
    ) -> Subject {
        isolatedValue.withValue { $0[keyPath: keyPath] }
    }
}

@dynamicMemberLookup
private final class _LockIsolated<Value>: @unchecked Sendable {
    // MARK: - Properties

    private let lock = NSRecursiveLock()

    private var _value: Value

    // MARK: - Init

    fileprivate init(_ value: @autoclosure () throws -> Value) rethrows {
        _value = try value()
    }

    // MARK: - Access / Mutation

    func setValue(
        _ newValue: @autoclosure () throws -> Value
    ) rethrows {
        try lock.sync {
            _value = try newValue()
        }
    }

    func withValue<T>(
        _ operation: (inout Value) throws -> T
    ) rethrows -> T {
        try lock.sync {
            // Operate on a local copy rather than passing &_value directly.
            // If `operation` re-enters the lock and reads _value (e.g. via
            // `wrappedValue.getter`), Swift's exclusivity checker would abort
            // because `&_value` would be simultaneously read-borrowed while
            // the inout write-borrow from `operation` is still active.
            // Using a copy keeps the inout borrow on the local variable,
            // leaving _value free for re-entrant reads within the same thread.
            var value = _value
            defer { _value = value }
            return try operation(&value)
        }
    }

    // MARK: - Dynamic Member Lookup

    fileprivate subscript<Subject>(
        dynamicMember keyPath: KeyPath<Value, Subject>
    ) -> Subject {
        lock.sync { _value[keyPath: keyPath] }
    }
}

extension LockIsolated: Sendable where Value: Sendable {}
extension LockIsolatedProjection: Sendable where Value: Sendable {}

public extension LockIsolatedProjection {
    func contains<Element: Hashable>(
        _ element: Element
    ) -> Bool where Value == Set<Element> {
        isolatedValue.withValue { $0.contains(element) }
    }

    func formUnion<Element: Hashable>(
        _ other: Set<Element>
    ) where Value == Set<Element> {
        isolatedValue.withValue { $0.formUnion(other) }
    }

    @discardableResult
    func insert<Element: Hashable>(
        _ element: Element
    ) -> (inserted: Bool, memberAfterInsert: Element) where Value == Set<Element> {
        isolatedValue.withValue { $0.insert(element) }
    }

    @discardableResult
    func remove<Element: Hashable>(
        _ element: Element
    ) -> Element? where Value == Set<Element> {
        isolatedValue.withValue { $0.remove(element) }
    }
}

public extension LockIsolatedProjection {
    subscript<Element>(
        index: Int
    ) -> Element where Value == [Element] {
        get {
            isolatedValue.withValue { $0[index] }
        }
        nonmutating set {
            isolatedValue.withValue { $0[index] = newValue }
        }
    }

    func append<Element>(_ element: Element) where Value == [Element] {
        isolatedValue.withValue { $0.append(element) }
    }

    @discardableResult
    func removeLast<Element>() -> Element where Value == [Element] {
        isolatedValue.withValue { $0.removeLast() }
    }
}

public extension LockIsolatedProjection {
    subscript<Key: Hashable, Element>(
        key: Key
    ) -> Element? where Value == [Key: Element] {
        get {
            isolatedValue.withValue { $0[key] }
        }
        nonmutating set {
            isolatedValue.withValue { $0[key] = newValue }
        }
    }
}

public extension NSRecursiveLock {
    @discardableResult
    @inlinable
    @_spi(Internals)
    func sync<R>(work: () throws -> R) rethrows -> R {
        lock()
        defer { unlock() }
        return try work()
    }
}

extension _LockIsolated {
    var value: Value {
        lock.sync { _value }
    }
}
