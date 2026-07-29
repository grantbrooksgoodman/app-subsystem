//
//  EventStream.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A broadcaster for occurrences that carry a typed payload.
///
/// Use `EventStream` when only the occurrence of something matters – a
/// signal to refresh, a captured screenshot, or a delta describing what
/// changed. An `EventStream` stores nothing; subscribers receive only the
/// events sent after they subscribe. For values with a meaningful current
/// state, use ``StateStream`` instead.
///
/// Declare events as computed properties on ``SharedEvents``. Use
/// `EventStream<Void>` when the event carries no payload:
///
/// ```swift
/// public extension SharedEvents {
///     var sessionDidExpire: EventStream<Void> { event() }
///     var storeDidChange: EventStream<StoreChange> { event() }
/// }
/// ```
///
/// Access declared events through the ``SharedEvent`` property wrapper
/// and send from any isolation context:
///
/// ```swift
/// @SharedEvent(\.storeDidChange) private var storeDidChange
///
/// storeDidChange.send(change)
/// ```
///
/// ## Subscribing to Events
///
/// The ``events`` property vends an independent `AsyncStream` for each
/// access:
///
/// ```swift
/// for await change in storeDidChange.events {
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
/// - SeeAlso: ``StateStream``
public final class EventStream<Payload: Sendable>: Sendable {
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
    /// for await change in storeDidChange.events {
    ///     // Handle every change.
    /// }
    /// ```
    ///
    /// The stream finishes when the `EventStream` deallocates.
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

public extension EventStream where Payload == Void {
    /// Notifies every active ``events`` subscriber that this event occurred.
    ///
    /// Use this convenience for signal-style events that carry no payload:
    ///
    ///     sessionDidExpire.send()
    func send() {
        send(())
    }
}
