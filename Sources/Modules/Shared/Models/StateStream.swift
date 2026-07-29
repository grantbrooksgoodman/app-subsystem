//
//  StateStream.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A thread-safe container for a value whose changes are shared with
/// asynchronous subscribers.
///
/// Use `StateStream` for values that cross feature boundaries and have a
/// meaningful current value at every point in time – authentication state,
/// visibility flags, or the most recently published configuration. When only
/// the occurrence of something matters, use ``EventStream`` instead.
///
/// Declare shared state as computed properties on ``SharedStates``:
///
/// ```swift
/// public extension SharedStates {
///     var isLoggedIn: StateStream<Bool> { state(false) }
/// }
/// ```
///
/// Read or write the current value through the ``SharedState``
/// property wrapper:
///
/// ```swift
/// @SharedState(\.isLoggedIn) private var isLoggedIn
///
/// isLoggedIn = true
/// ```
///
/// ## Subscribing to Changes
///
/// The ``changes`` property vends an independent `AsyncStream` for each
/// access. The stream yields the current value immediately upon subscription,
/// then each subsequently written value:
///
/// ```swift
/// for await isLoggedIn in $isLoggedIn.changes {
///     // Handle the current value, then each change.
/// }
/// ```
///
/// View models subscribe with ``ViewModelOf/observing(_:_:)``, mapping each
/// value to a reducer action.
///
/// ## Thread Safety
///
/// All stored state is protected by ``LockIsolated``. The ``value`` property
/// can be read and written from any isolation context. Writes are delivered
/// to every subscriber in write order.
///
/// - SeeAlso: ``EventStream``
public final class StateStream<Value: Sendable>: Sendable {
    // MARK: - Types

    private struct Storage {
        var continuations = [UUID: AsyncStream<Value>.Continuation]()
        var value: Value
    }

    // MARK: - Properties

    private let storage: LockIsolated<Storage>

    // MARK: - Computed Properties

    /// An asynchronous sequence of the current value and its changes.
    ///
    /// Each access creates an independent stream. The stream yields the
    /// current value immediately upon subscription, then each value written
    /// to ``value``, in write order:
    ///
    /// ```swift
    /// for await isLoggedIn in $isLoggedIn.changes {
    ///     guard isLoggedIn else { continue }
    ///     // Handle login
    /// }
    /// ```
    ///
    /// If the consumer suspends while multiple writes occur, only the most
    /// recent value is retained; intermediate values are discarded. Values
    /// that must never be dropped are events, not state – model them with
    /// ``EventStream``.
    ///
    /// The stream finishes when the `StateStream` deallocates.
    public var changes: AsyncStream<Value> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let id = UUID()

            continuation.onTermination = { [weak self] _ in
                self?.storage.projectedValue.withValue { $0.continuations[id] = nil }
            }

            storage.projectedValue.withValue { storage in
                storage.continuations[id] = continuation
                continuation.yield(storage.value)
            }
        }
    }

    /// The current value.
    ///
    /// Reading this property returns the latest value. Writing a new value
    /// stores it and yields it to every active ``changes`` subscriber. The
    /// store and the yields are performed as a single atomic operation, so
    /// concurrent writers cannot interleave and every subscriber observes
    /// writes in the same order.
    public var value: Value {
        get { storage.projectedValue.value }
        set {
            storage.projectedValue.withValue { storage in
                storage.value = newValue
                for continuation in storage.continuations.values {
                    continuation.yield(newValue)
                }
            }
        }
    }

    // MARK: - Object Lifecycle

    /// Creates a shared state container with the given initial value.
    ///
    /// - Parameter initialValue: The initial value to store.
    public init(_ initialValue: Value) {
        storage = LockIsolated(Storage(value: initialValue))
    }

    deinit {
        storage.projectedValue.withValue { storage in
            storage.continuations.values.forEach { $0.finish() }
            storage.continuations.removeAll()
        }
    }

    // MARK: - Methods

    /// Atomically reads and mutates the current value as a single isolated
    /// operation, then yields the result to every active ``changes``
    /// subscriber.
    ///
    /// Use this method instead of separate reads and writes of ``value``
    /// when the new value depends on the old one; performing the mutation
    /// in a single isolated operation prevents concurrent writers from
    /// interleaving:
    ///
    /// ```swift
    /// $isBuildInfoOverlayHidden.withValue { $0.toggle() }
    /// ```
    ///
    /// The resulting value is yielded to subscribers after `operation`
    /// returns, whether or not `operation` changed it.
    ///
    /// - Parameter operation: A closure that receives the current value as
    ///   an `inout` parameter.
    ///
    /// - Returns: The value returned by `operation`.
    @discardableResult
    public func withValue<T>(
        _ operation: (inout Value) throws -> T
    ) rethrows -> T {
        try storage.projectedValue.withValue { storage in
            let result = try operation(&storage.value)
            for continuation in storage.continuations.values {
                continuation.yield(storage.value)
            }

            return result
        }
    }
}
