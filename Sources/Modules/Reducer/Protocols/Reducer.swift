//
//  Reducer.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A type that describes how app state changes in response to
/// actions.
///
/// The `Reducer` protocol is the core building block of state management.
/// Each reducer defines a `State` type that holds the data a feature needs,
/// an `Action` type that enumerates the events it can handle, and a
/// ``reduce(into:action:)`` method that applies an action to the state and
/// optionally returns an ``Effect`` for asynchronous follow-up work.
///
/// ## Implementing a Reducer
///
/// Define a struct that conforms to `Reducer`, declare nested `State` and
/// `Action` types, and implement ``reduce(into:action:)``:
///
/// ```swift
/// struct CounterReducer: Reducer {
///     struct State: Equatable {
///         var count = 0
///     }
///
///     enum Action {
///         case increment
///         case decrement
///         case reset
///     }
///
///     func reduce(into state: inout State, action: Action) -> Effect<Action> {
///         switch action {
///         case .increment:
///             state.count += 1
///         case .decrement:
///             state.count -= 1
///         case .reset:
///             state.count = 0
///         }
///
///         return .none
///     }
/// }
/// ```
///
/// When an action requires asynchronous work, return an ``Effect`` instead
/// of `.none`. The effect runs after the state change and can send
/// additional actions back into the reducer.
///
/// ## Connecting to a View
///
/// Pass the reducer and its initial state to a ``ViewModel``, then use
/// the view model in your SwiftUI view:
///
///     @StateObject var viewModel = ViewModel(
///         initialState: CounterReducer.State(),
///         reducer: CounterReducer()
///     )
///
/// - Note: Reducers are main actor-isolated. State mutations and effect
///   creation always run on the main actor.
///
/// - SeeAlso: ``Effect``, ``ViewModel``, ``Reduce``
@MainActor
public protocol Reducer<State, Action> {
    // MARK: - Associated Types

    /// The type that enumerates the events this reducer can handle.
    associatedtype Action: Sendable

    /// The type of this reducer's composed body. Use `Never` when the
    /// reducer implements ``reduce(into:action:)`` directly.
    associatedtype ReducerBody

    /// The type that holds the data this reducer manages.
    associatedtype State: Equatable

    // MARK: - Properties

    /// The composed body of this reducer, built using ``ReducerBuilder``.
    ///
    /// Override this property to compose multiple child reducers. When
    /// implementing ``reduce(into:action:)`` directly, leave
    /// `ReducerBody` as `Never` and do not provide a body.
    @ReducerBuilder<State, Action> var body: ReducerBody { get }

    // MARK: - Methods

    /// Applies an action to the state and returns an effect.
    ///
    /// Modify `state` in place to reflect the action, then return an
    /// ``Effect`` describing any asynchronous work that should follow.
    /// Return ``Effect/none`` when no follow-up work is needed.
    ///
    /// - Parameters:
    ///   - state: The current state, passed as `inout` so that it can be
    ///     modified in place.
    ///   - action: The action to apply.
    ///
    /// - Returns: An effect describing any asynchronous follow-up work, or
    ///   ``Effect/none``.
    func reduce(
        into state: inout State,
        action: Action
    ) -> Effect<Action>
}

public extension Reducer where ReducerBody == Never {
    var body: ReducerBody { fatalError("Body may not be called directly") }
}
