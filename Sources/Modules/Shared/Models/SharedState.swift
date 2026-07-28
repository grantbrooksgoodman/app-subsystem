//
//  SharedState.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A thread-safe container for a value whose changes are shared with
/// asynchronous subscribers.
///
/// Use `SharedState` for values that cross feature boundaries and have a
/// meaningful current value at every point in time – authentication state,
/// visibility flags, or the most recently published configuration. When only
/// the occurrence of something matters, use ``SharedEvent`` instead.
///
/// Declare shared state as static properties on the `Shared` namespace:
///
/// ```swift
/// public extension Shared {
///     static let isLoggedIn = SharedState<Bool>(false)
/// }
/// ```
///
/// Read or write the current value through the ``value`` property:
///
///     Shared.isLoggedIn.value = true
///
/// ## Subscribing to Changes
///
/// The ``changes`` property vends an independent `AsyncStream` for each
/// access. The stream yields the current value immediately upon subscription,
/// then each subsequently written value:
///
/// ```swift
/// for await isLoggedIn in Shared.isLoggedIn.changes {
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
/// - SeeAlso: ``SharedEvent``
public final class SharedState<Value: Sendable>: Sendable {
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
    /// for await isLoggedIn in Shared.isLoggedIn.changes {
    ///     guard isLoggedIn else { continue }
    ///     // Handle login
    /// }
    /// ```
    ///
    /// If the consumer suspends while multiple writes occur, only the most
    /// recent value is retained; intermediate values are discarded. Values
    /// that must never be dropped are events, not state – model them with
    /// ``SharedEvent``.
    ///
    /// The stream finishes when the `SharedState` deallocates.
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
}
