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
///     public enum Observables {
///         static let isLoggedIn = Observable<Bool>(false)
///         static let sessionDidExpire = Observable<Nil>()
///     }
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
///     func onChange(of observable: Observable<Any>) {
///         switch observable {
///         case Observables.isLoggedIn:
///             send(.refreshUI)
///         default: ()
///         }
///     }
///
/// The pattern-matching operator (`~=`) compares the identity of the
/// observable that originally changed against the candidate passed to your
/// observer, so each `case` uniquely identifies a single source of truth.
///
/// ## Thread Safety
///
/// All stored state is protected by ``LockIsolated``. The ``value`` property
/// can be read and written from any thread. Observer callbacks are always
/// dispatched to the main actor, so UI updates can be performed directly
/// inside ``Observer/onChange(of:)``.
public final class Observable<T>: ObservableProtocol, @unchecked Sendable {
    // MARK: - Properties

    private let observers = LockIsolated<[any Observer]>(wrappedValue: [])
    private let _value: LockIsolated<T>

    // Set only on notification objects.
    // Real observables leave this nil — their identity is ObjectIdentifier(self).
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
            dispatchChange(newValue as Any)
        }
    }

    // MARK: - Object Lifecycle

    /// Creates an observable with the given initial value.
    ///
    /// - Parameter initialValue: The initial value to store.
    public init(_ initialValue: T) {
        originID = nil
        _value = LockIsolated(wrappedValue: initialValue)
    }

    // Used internally to stamp notification objects with their originator's identity.
    fileprivate init(
        _ initialValue: T,
        originID: ObjectIdentifier
    ) {
        self.originID = originID
        _value = LockIsolated(wrappedValue: initialValue)
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
}

public func ~= (
    pattern: Observable<some Any>,
    candidate: Observable<Any>
) -> Bool {
    candidate.originID == ObjectIdentifier(pattern)
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
            for observer in observers { $0.append(observer) }
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
