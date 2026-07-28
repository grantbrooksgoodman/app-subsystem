//
//  Observable.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A type alias for `NSNull`, used as the type parameter for observables that
/// carry no payload.
///
/// When an observable represents an event rather than a changing value, use
/// `Observable<Nil>` to signal that only the occurrence matters:
///
///     static let userDidLogOut = Observable<Nil>()
///
/// - SeeAlso: ``Observable``
public typealias Nil = NSNull

/// A thread-safe container that notifies registered observers when its value
/// changes.
///
/// Declare observables as static properties on a shared namespace such as an
/// `Observables` enum. Each observable acts as both the storage for a value
/// and the identity used to match it inside an observer's ``Observer/onChange(of:)``
/// implementation:
///
/// ```swift
/// public enum Observables {
///     static let isLoggedIn = Observable<Bool>(false)
///     static let sessionDidExpire = Observable<Nil>()
/// }
/// ```
///
/// Read or write the current value through the ``value`` property. Setting a
/// new value automatically notifies all registered observers on the main actor:
///
///     Observables.isLoggedIn.value = true
///
/// For observables that carry no payload (`Observable<Nil>`), use
/// ``trigger()`` instead of assigning a value:
///
///     Observables.sessionDidExpire.trigger()
///
/// ## Responding to Changes
///
/// Conform to the ``Observer`` protocol and list the observables you want to
/// watch. Inside ``Observer/onChange(of:)``, use a `switch` statement to
/// pattern-match the incoming observable against the ones you declared:
///
/// ```swift
/// func onChange(of observable: Observable<Any>) {
///     switch observable {
///         case Observables.isLoggedIn:
///             send(.refreshUI)
///         default: ()
///     }
/// }
/// ```
///
/// The pattern-matching operator (`~=`) compares the identity of the
/// observable that originally changed against the candidate passed to your
/// observer, so each `case` uniquely identifies a single source of truth.
///
/// To respond to changes from contexts that have no view lifetime to anchor
/// a ``ViewObserver`` to, such as services, iterate the asynchronous
/// ``values`` stream instead:
///
///     for await value in Observables.isLoggedIn.values { ... }
///
/// ## Thread Safety
///
/// All stored state is protected by ``LockIsolated``. The ``value`` property
/// can be read and written from any thread. Observer callbacks are always
/// dispatched to the main actor, so UI updates can be performed directly
/// inside ``Observer/onChange(of:)``.
public final class Observable<T>: ObservableProtocol, @unchecked Sendable {
    // MARK: - Properties

    private let observers = LockIsolated([any Observer]())
    private let streamHandlers = LockIsolated([UUID: @Sendable (T) -> Void]())
    private let _value: LockIsolated<T>

    /// Set only on notification objects.
    /// Real observables leave this nil – their identity is ObjectIdentifier(self).
    fileprivate let originID: ObjectIdentifier?

    // MARK: - Computed Properties

    /// The current value of the observable.
    ///
    /// Reading this property returns the latest value. Writing a new value
    /// stores it and notifies all registered observers on the main actor.
    public var value: T {
        get { _value.wrappedValue }
        set {
            _value.wrappedValue = newValue
            yieldToStreams(newValue)
            dispatchChange(newValue as Any)
        }
    }

    // MARK: - Object Lifecycle

    /// Creates an observable with the given initial value.
    ///
    /// - Parameter initialValue: The initial value to store.
    public init(_ initialValue: T) {
        originID = nil
        _value = LockIsolated(initialValue)
    }

    /// Used internally to record the originator's identity on notification objects.
    fileprivate init(
        _ initialValue: T,
        originID: ObjectIdentifier
    ) {
        self.originID = originID
        _value = LockIsolated(initialValue)
    }

    deinit {
        observers.wrappedValue = []
    }

    // MARK: - Notification

    /// Notifies the given observers of the current value. The notification is
    /// dispatched to the main actor, matching the behavior of the `value` setter.
    func notify(_ observers: [any Observer]) {
        guard !observers.isEmpty else { return }
        dispatchChange(value as Any, to: observers)
    }

    // MARK: - Auxiliary

    private func dispatchChange(_ anyValue: Any) {
        let observersSnapshot = observers.wrappedValue
        guard !observersSnapshot.isEmpty else { return }
        dispatchChange(anyValue, to: observersSnapshot)
    }

    private func dispatchChange(
        _ anyValue: Any,
        to observers: [any Observer]
    ) {
        let observable = Observable<Any>(
            anyValue,
            originID: ObjectIdentifier(self)
        )

        Task { @MainActor in
            observers.forEach { $0.onChange(of: observable) }
        }
    }

    private func yieldToStreams(_ value: T) {
        streamHandlers.wrappedValue.values.forEach { $0(value) }
    }
}

public func ~= (
    pattern: Observable<some Any>,
    candidate: Observable<Any>
) -> Bool {
    candidate.originID == ObjectIdentifier(pattern)
}

public extension Observable where T: Sendable {
    /// An asynchronous sequence of value changes.
    ///
    /// Each access creates an independent stream that yields the observable's
    /// value each time it changes. The stream does not yield the current
    /// value upon creation; read ``value`` to inspect the latest state before
    /// iterating.
    ///
    /// Use `values` to respond to changes from contexts that have no view
    /// lifetime to anchor a ``ViewObserver`` to, such as services:
    ///
    /// ```swift
    /// for await isLoggedIn in Observables.isLoggedIn.values {
    ///     guard isLoggedIn else { continue }
    ///     // Handle login
    /// }
    /// ```
    ///
    /// If the consumer suspends while multiple changes occur, only the most
    /// recent value is retained; intermediate values are discarded. To receive
    /// every value regardless of consumer timing, use ``values(bufferingPolicy:)``
    /// with an `.unbounded` buffering policy.
    ///
    /// The stream finishes when the observable is deallocated.
    var values: AsyncStream<T> {
        values(bufferingPolicy: .bufferingNewest(1))
    }

    /// Returns an asynchronous sequence of value changes, buffering values
    /// according to the given policy.
    ///
    /// Each access creates an independent stream that yields the observable's
    /// value each time it changes. The stream does not yield the current
    /// value upon creation; read ``value`` to inspect the latest state before
    /// iterating.
    ///
    /// Unlike ``values``, which retains only the most recent value while the
    /// consumer is suspended, this method lets you choose how intermediate
    /// values are buffered. Pass `.unbounded` when every change must be
    /// observed, such as when values carry deltas rather than absolute state:
    ///
    /// ```swift
    /// for await change in Observables.storeDidChange.values(
    ///     bufferingPolicy: .unbounded
    /// ) {
    ///     // Handle every change.
    /// }
    /// ```
    ///
    /// The stream finishes when the observable is deallocated.
    ///
    /// - Parameter bufferingPolicy: The policy governing how values are
    ///   buffered while the consumer is suspended.
    /// - Returns: An asynchronous stream of the observable's value changes.
    func values(
        bufferingPolicy: AsyncStream<T>.Continuation.BufferingPolicy
    ) -> AsyncStream<T> {
        AsyncStream(bufferingPolicy: bufferingPolicy) { continuation in
            let id = UUID()

            continuation.onTermination = { [weak self] _ in
                self?.streamHandlers.projectedValue.withValue { $0[id] = nil }
            }

            streamHandlers.projectedValue[id] = { continuation.yield($0) }
        }
    }
}

extension Observable: ObserverRegistrable {
    func clearObservers(ofType type: Any.Type) {
        observers.projectedValue.withValue {
            $0.removeAll { Swift.type(of: $0) == type }
        }
    }

    func setObservers(
        ofType type: Any.Type,
        _ observers: [any Observer]
    ) {
        self.observers.projectedValue.withValue {
            $0.removeAll { Swift.type(of: $0) == type }
            for observer in observers {
                $0.append(observer)
            }
        }
    }
}

public extension Observable<Nil> {
    /// Creates an observable that carries no payload.
    ///
    /// Use this initializer for event-style observables where only the
    /// occurrence of the event matters, not a specific value:
    ///
    ///     static let userDidLogOut = Observable<Nil>()
    convenience init() {
        self.init(Nil())
    }

    /// Notifies all registered observers that this event occurred.
    ///
    /// Unlike setting ``value`` on a typed observable, `trigger()` does not
    /// carry a meaningful payload. Use it for signal-style observables where
    /// only the occurrence matters:
    ///
    ///     Observables.userDidLogOut.trigger()
    func trigger() {
        yieldToStreams(Nil())
        let observersSnapshot = observers.wrappedValue
        guard !observersSnapshot.isEmpty else { return }
        let observable = Observable<Any>(
            Nil(),
            originID: ObjectIdentifier(self)
        )

        Task { @MainActor in
            observersSnapshot.forEach { $0.onChange(of: observable) }
        }
    }
}
