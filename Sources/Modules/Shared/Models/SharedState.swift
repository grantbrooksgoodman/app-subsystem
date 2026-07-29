//
//  SharedState.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A property wrapper that reads and writes a shared value from the
/// current dependency scope.
///
/// Use `@SharedState` in reducers, services, and effects to access a
/// ``StateStream`` declared on ``SharedStates`` by its key path:
///
/// ```swift
/// @SharedState(\.isLoggedIn) private var isLoggedIn
///
/// isLoggedIn = true                // Writes the shared value.
/// guard isLoggedIn else { return } // Reads the shared value.
/// ```
///
/// The projected value (`$`) exposes the underlying ``StateStream``,
/// providing access to ``StateStream/changes`` and
/// ``StateStream/withValue(_:)``:
///
/// ```swift
/// viewModel.observing($isLoggedIn.changes) { .loginStateChanged($0) }
/// ```
///
/// Events have their own wrapper – access an ``EventStream`` through
/// ``SharedEvent`` instead:
///
/// ```swift
/// @SharedEvent(\.sessionDidExpire) private var sessionDidExpire
/// ```
///
/// This wrapper is the only way to access a ``StateStream`` – the
/// ``SharedStates`` container is not resolvable through ``Dependency``.
///
/// The wrapper resolves its value from ``DependencyValues/current`` each
/// time you access ``wrappedValue`` or ``projectedValue``, so overrides
/// applied by ``DependencyScopes/withDependencies(_:operation:)`` are
/// visible to any access within that scope.
///
/// - Important: This wrapper is not a SwiftUI `DynamicProperty`. Reading a
///   shared value in a view's `body` doesn't invalidate the view when the
///   value changes. Reactivity flows exclusively through
///   ``ViewModelOf/observing(_:_:)`` – map each change to a reducer action
///   and drive view updates from reducer state.
///
/// - SeeAlso: ``SharedStates``, ``StateStream``, ``EventStream``
@propertyWrapper
public struct SharedState<Value: Sendable>: @unchecked Sendable {
    // MARK: - Properties

    private let keyPath: KeyPath<SharedStates, StateStream<Value>>

    // MARK: - Init

    /// Creates a shared value accessor for the given key path.
    ///
    /// - Parameter keyPath: A key path to the desired ``StateStream``
    ///   declaration on ``SharedStates``.
    public init(_ keyPath: KeyPath<SharedStates, StateStream<Value>>) {
        self.keyPath = keyPath
    }

    // MARK: - Projected Value

    /// The underlying ``StateStream`` instance.
    ///
    /// Use the projected value to subscribe to ``StateStream/changes`` or
    /// to perform an atomic read-modify-write with
    /// ``StateStream/withValue(_:)``.
    public var projectedValue: StateStream<Value> {
        DependencyValues.current.sharedStates[keyPath: keyPath]
    }

    // MARK: - Wrapped Value

    /// The current value of the shared state.
    ///
    /// Reading this property resolves the ``StateStream`` instance from
    /// the ``DependencyValues`` scope that is active at the point of
    /// access and returns its current value. Writing stores the new value
    /// and yields it to every active ``StateStream/changes`` subscriber.
    public var wrappedValue: Value {
        get { projectedValue.value }
        nonmutating set { projectedValue.value = newValue }
    }
}
