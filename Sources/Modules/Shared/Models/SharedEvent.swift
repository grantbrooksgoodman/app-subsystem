//
//  SharedEvent.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A property wrapper that reads a shared event from the current
/// dependency scope.
///
/// Use `@SharedEvent` in reducers, services, and effects to access an
/// ``EventStream`` declared on ``SharedEvents`` by its key path:
///
/// ```swift
/// @SharedEvent(\.sessionDidExpire) private var sessionDidExpire
///
/// sessionDidExpire.send()
/// ```
///
/// View models subscribe with ``ViewModelOf/observing(_:_:)``, mapping
/// each payload to a reducer action:
///
/// ```swift
/// viewModel.observing(sessionDidExpire.events) { _ in .sessionExpired }
/// ```
///
/// State has its own wrapper – access a ``StateStream`` through
/// ``SharedState`` instead. This wrapper is the only way to access an
/// ``EventStream`` – the ``SharedEvents`` container is not resolvable
/// through ``Dependency``.
///
/// The wrapper resolves its value from ``DependencyValues/current`` each
/// time you access ``wrappedValue``, so overrides applied by
/// ``DependencyScopes/withDependencies(_:operation:)`` are visible to any
/// access within that scope.
///
/// - SeeAlso: ``SharedEvents``, ``EventStream``, ``SharedState``
@propertyWrapper
public struct SharedEvent<Payload: Sendable>: @unchecked Sendable {
    // MARK: - Properties

    private let keyPath: KeyPath<SharedEvents, EventStream<Payload>>

    // MARK: - Init

    /// Creates a shared event accessor for the given key path.
    ///
    /// - Parameter keyPath: A key path to the desired ``EventStream``
    ///   declaration on ``SharedEvents``.
    public init(_ keyPath: KeyPath<SharedEvents, EventStream<Payload>>) {
        self.keyPath = keyPath
    }

    // MARK: - Wrapped Value

    /// The underlying ``EventStream`` instance.
    ///
    /// Reading this property resolves the instance from the
    /// ``DependencyValues`` scope that is active at the point of access.
    /// Send events with ``EventStream/send(_:)`` and subscribe through
    /// ``EventStream/events``.
    public var wrappedValue: EventStream<Payload> {
        DependencyValues.current.sharedEvents[keyPath: keyPath]
    }
}
