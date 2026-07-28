//
//  SharedEvent.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A broadcaster for occurrences that carry a typed payload.
///
/// Use `SharedEvent` when only the occurrence of something matters – a
/// signal to refresh, a captured screenshot, or a delta describing what
/// changed. A `SharedEvent` stores nothing; subscribers receive only the
/// events sent after they subscribe. For values with a meaningful current
/// state, use ``SharedState`` instead.
///
/// Declare events as static properties on the `Shared` namespace. Use
/// `SharedEvent<Void>` when the event carries no payload:
///
/// ```swift
/// public extension Shared {
///     static let sessionDidExpire = SharedEvent<Void>()
///     static let storeDidChange = SharedEvent<StoreChange>()
/// }
/// ```
///
/// Send an event from any isolation context:
///
///     Shared.sessionDidExpire.send()
///     Shared.storeDidChange.send(change)
///
/// ## Subscribing to Events
///
/// The ``events`` property vends an independent `AsyncStream` for each
/// access:
///
/// ```swift
/// for await change in Shared.storeDidChange.events {
///     // Handle every change.
/// }
/// ```
///
/// View models subscribe with ``ViewModelOf/observing(_:_:)``, mapping each
/// payload to a reducer action.
///
/// ## Thread Safety
///
/// All stored state is protected by ``LockIsolated``. Events can be sent
/// from any isolation context and are delivered to every subscriber in send
/// order. Payloads are buffered without bound, so no event is dropped while
/// a subscriber is suspended.
///
/// - SeeAlso: ``SharedState``
public final class SharedEvent<Payload: Sendable>: Sendable {
    // MARK: - Properties

    private let continuations = LockIsolated([UUID: AsyncStream<Payload>.Continuation]())

    // MARK: - Computed Properties

    /// An asynchronous sequence of event payloads.
    ///
    /// Each access creates an independent stream that yields the payload of
    /// each event sent after subscription; events sent beforehand are not
    /// replayed. Payloads are buffered without bound, so every event is
    /// delivered even if the consumer suspends while multiple events occur:
    ///
    /// ```swift
    /// for await change in Shared.storeDidChange.events {
    ///     // Handle every change.
    /// }
    /// ```
    ///
    /// The stream finishes when the `SharedEvent` deallocates.
    public var events: AsyncStream<Payload> {
        AsyncStream { continuation in
            let id = UUID()

            continuation.onTermination = { [weak self] _ in
                self?.continuations.projectedValue[id] = nil
            }

            continuations.projectedValue[id] = continuation
        }
    }

    // MARK: - Object Lifecycle

    /// Creates a shared event broadcaster.
    public init() {}

    deinit {
        continuations.projectedValue.withValue { continuations in
            continuations.values.forEach { $0.finish() }
            continuations.removeAll()
        }
    }

    // MARK: - Methods

    /// Delivers the given payload to every active ``events`` subscriber.
    ///
    /// The yields to all subscribers are performed as a single atomic
    /// operation, so concurrent senders cannot interleave and every
    /// subscriber observes events in the same order.
    ///
    /// - Parameter payload: The payload to deliver.
    public func send(_ payload: Payload) {
        continuations.projectedValue.withValue { continuations in
            for continuation in continuations.values {
                continuation.yield(payload)
            }
        }
    }
}

public extension SharedEvent where Payload == Void {
    /// Notifies every active ``events`` subscriber that this event occurred.
    ///
    /// Use this convenience for signal-style events that carry no payload:
    ///
    ///     Shared.sessionDidExpire.send()
    func send() {
        send(())
    }
}
