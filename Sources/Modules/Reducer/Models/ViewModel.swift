//
//  ViewModel.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Combine
import Foundation
import SwiftUI

/// A convenience alias that derives the `State` and `Action` types
/// from a ``Reducer`` conformance.
///
/// Use `ViewModel` when the reducer type is known at the declaration
/// site:
///
/// ```swift
/// @StateObject var viewModel = ViewModel<CounterReducer>(
///    initialState: .init(),
///    reducer: CounterReducer()
/// )
/// ```
///
/// When the state and action types are specified directly – for
/// example, in a generic context – use ``ViewModelOf`` instead.
public typealias ViewModel<R> = ViewModelOf<R.State, R.Action> where R: Reducer

/// The runtime that drives a feature's state management cycle.
///
/// `ViewModelOf` is a main-actor-isolated `ObservableObject` that
/// pairs a ``Reducer`` with a published ``state`` value. It forms
/// the bridge between SwiftUI views and the unidirectional data flow
/// defined by the reducer:
///
/// 1. The view reads ``state`` (or its members via dynamic member
///    lookup) and re-renders when the state changes.
/// 2. The view calls ``send(_:)`` to dispatch an action.
/// 3. The reducer applies the action to the state and returns an
///    ``Effect``.
/// 4. The runtime executes the effect, which may send additional
///    actions back into step 3.
///
/// ```swift
/// struct CounterView: View {
///     @StateObject var viewModel = ViewModel<CounterReducer>(
///         initialState: .init(),
///         reducer: CounterReducer()
///     )
///
///     var body: some View {
///         Text("\(viewModel.count)")
///         Button("Increment") { viewModel.send(.increment) }
///     }
/// }
/// ```
///
/// ## Bindings
///
/// Create two-way bindings to state values with
/// ``binding(for:)``. The simplest form produces a read-only
/// binding; pass a `sendAction` closure to dispatch an action
/// whenever the binding's value changes:
///
/// ```swift
/// Toggle(
///     "Enabled",
///     isOn: viewModel.binding(
///         for: \.isEnabled,
///         sendAction: { .setEnabled($0) }
///     )
/// )
/// ```
///
/// ## Long-Running Effects
///
/// Use ``send(_:while:)`` to dispatch an action and suspend until
/// the state no longer satisfies a predicate. This is useful for
/// loading flows where the caller needs to wait for a result:
///
///     await viewModel.send(.refresh, while: \.isLoading)
///
/// ## Observing Shared Values
///
/// Use ``observing(_:_:)`` to subscribe the view model to an
/// asynchronous sequence, such as a ``StateStream/changes`` or
/// ``EventStream/events`` stream, mapping each element to an
/// action. Subscriptions are cancelled automatically when the view
/// model deinitializes.
///
/// - Important: `ViewModelOf` is confined to the main actor. Always
///   access ``state`` and call ``send(_:)`` from the main actor.
///   A runtime assertion will be triggered if this invariant is violated.
///
/// - Warning: The `Task` returned by ``send(_:)`` represents the
///   effect's lifetime, not the state mutation. The state is updated
///   synchronously *before* the task begins. Awaiting the task waits
///   for the effect to complete, which may never finish for
///   long-running effects such as observation streams. Use
///   ``sendCancellableAction(_:)`` or ``send(_:while:)`` when you
///   need structured cancellation.
@dynamicMemberLookup
@MainActor
public final class ViewModelOf<State: Equatable, Action>: ObservableObject {
    // MARK: - Properties

    /// The current state of the feature.
    ///
    /// This property is published and triggers SwiftUI view updates
    /// whenever it changes. The value is read-only from outside the
    /// view model; state mutations happen exclusively through the
    /// reducer when an action is sent.
    ///
    /// You can read individual state members directly on the view
    /// model thanks to `@dynamicMemberLookup`:
    ///
    ///     viewModel.count  // equivalent to viewModel.state.count
    @Published public private(set) var state: State

    private let reducer: any Reducer<State, Action>

    private var internalState: State
    private var observationTasks = [Task<Void, Never>]()

    // MARK: - Object Lifecycle

    /// Creates a view model with the given initial state and
    /// reducer.
    ///
    /// The view model takes ownership of state management
    /// immediately. Pass this instance to a SwiftUI view as a
    /// `@StateObject` or `@ObservedObject`.
    ///
    /// - Parameters:
    ///   - initialState: The state value the feature starts with.
    ///   - reducer: The reducer that processes actions and produces
    ///     state changes and effects.
    public init(
        initialState: State,
        reducer: any Reducer<State, Action>
    ) {
        self.state = initialState
        self.internalState = initialState
        self.reducer = reducer
    }

    deinit {
        observationTasks.forEach { $0.cancel() }
    }

    // MARK: - Send

    /// Sends an action to the reducer and returns the effect's
    /// task.
    ///
    /// The reducer processes the action synchronously, updating
    /// ``state`` before this method returns. The returned `Task`
    /// represents the asynchronous effect, if any. You can discard
    /// it when no follow-up is needed:
    ///
    ///     viewModel.send(.increment)
    ///
    /// Or await it when the effect's completion matters:
    ///
    ///     await viewModel.send(.save).value
    ///
    /// - Parameter action: The action to send.
    ///
    /// - Returns: A task that completes when the effect finishes.
    @discardableResult
    public func send(_ action: Action) -> Task<Void, Never> {
        self._send(action)
    }

    /// Sends an action to the reducer, applying the given animation
    /// to any resulting state changes.
    ///
    /// - Parameters:
    ///   - action: The action to send.
    ///   - animation: The animation to apply to the state change.
    ///
    /// - Returns: A task that completes when the effect finishes.
    @discardableResult
    public func send(
        _ action: Action,
        animation: Animation?
    ) -> Task<Void, Never> {
        send(
            action,
            transaction: Transaction(animation: animation)
        )
    }

    /// Sends an action to the reducer within the given transaction.
    ///
    /// - Parameters:
    ///   - action: The action to send.
    ///   - transaction: The transaction to apply to the state
    ///     change.
    ///
    /// - Returns: A task that completes when the effect finishes.
    @discardableResult
    public func send(
        _ action: Action,
        transaction: Transaction
    ) -> Task<Void, Never> {
        withTransaction(transaction) {
            self._send(action)
        }
    }

    @discardableResult
    private func _send(_ action: Action) -> Task<Void, Never> {
        checkThreadPreconditions()
        let effect = updateState(for: action)
        return Task(priority: effect.priority) { [weak self] in
            await effect.operation(
                Send { [weak self] action in
                    self?.send(action)
                }
            )
        }
    }

    // MARK: - Cancellable

    /// Sends an action and awaits its effect with structured
    /// cancellation.
    ///
    /// Unlike ``send(_:)``, the effect's task is automatically
    /// cancelled when the calling task is cancelled. Use this method
    /// when the effect should not outlive the scope that initiated
    /// it:
    ///
    /// ```swift
    /// // The upload is cancelled if the view disappears.
    /// task = Task {
    ///     await viewModel.sendCancellableAction(.startUpload)
    /// }
    /// ```
    ///
    /// - Parameter action: The action to send.
    public func sendCancellableAction(_ action: Action) async {
        let task = send(action)
        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
    }

    // MARK: - Binding for Key Path

    /// Returns a read-only binding to a state value.
    ///
    /// The binding reflects the current state but does not send any
    /// action when its value changes. Use this form when the view
    /// needs to read a value but writes are handled elsewhere:
    ///
    ///     Text(viewModel.binding(for: \.title).wrappedValue)
    ///
    /// - Parameter keyPath: A key path to the state value.
    ///
    /// - Returns: A binding that reads from the current state.
    public func binding<Value>(for keyPath: KeyPath<State, Value>) -> Binding<Value> {
        binding(for: keyPath, sendAction: { _ in .none })
    }

    /// Returns a binding that sends an action derived from each new
    /// value.
    ///
    /// Each time the binding's setter is called, `valueToAction`
    /// converts the new value into an action and dispatches it to
    /// the reducer:
    ///
    /// ```swift
    /// TextField(
    ///     "Name",
    ///     text: viewModel.binding(
    ///         for: \.name,
    ///         sendAction: { .nameChanged($0) }
    ///     )
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - keyPath: A key path to the state value.
    ///   - valueToAction: A closure that converts the new value into
    ///     an action.
    ///   - animation: An optional animation applied to the state
    ///     change. The default is `nil`.
    ///
    /// - Returns: A two-way binding backed by the reducer.
    public func binding<Value>(
        for keyPath: KeyPath<State, Value>,
        sendAction valueToAction: @escaping (Value) -> Action,
        animation: Animation? = nil
    ) -> Binding<Value> {
        Binding<Value>(
            get: { self.state[keyPath: keyPath] },
            set: { value in
                let action = valueToAction(value)
                guard let animation else {
                    self.send(action)
                    return
                }

                self.send(
                    action,
                    animation: animation
                )
            }
        )
    }

    /// Returns a binding that optionally sends an action derived
    /// from each new value.
    ///
    /// This variant allows the closure to return `nil`, in which
    /// case no action is dispatched and the state is not modified.
    /// Use it when only some value changes are meaningful:
    ///
    /// ```swift
    /// viewModel.binding(
    ///     for: \.selection,
    ///     sendAction: { newValue -> Action? in
    ///         newValue != .placeholder ? .selected(newValue) : nil
    ///     }
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - keyPath: A key path to the state value.
    ///   - valueToAction: A closure that converts the new value into
    ///     an optional action. Return `nil` to suppress the
    ///     dispatch.
    ///   - animation: An optional animation applied to the state
    ///     change. The default is `nil`.
    ///
    /// - Returns: A two-way binding backed by the reducer.
    public func binding<Value>(
        for keyPath: KeyPath<State, Value>,
        sendAction valueToAction: @escaping (Value) -> Action?,
        animation: Animation? = nil
    ) -> Binding<Value> {
        Binding<Value>(
            get: { self.state[keyPath: keyPath] },
            set: { value in
                if let action = valueToAction(value) {
                    guard let animation else {
                        self.send(action)
                        return
                    }

                    self.send(
                        action,
                        animation: animation
                    )
                }
            }
        )
    }

    /// Returns a binding that sends a fixed action whenever the
    /// value changes.
    ///
    /// Use this form when the new value is irrelevant and the same
    /// action should fire for every change:
    ///
    ///     viewModel.binding(for: \.isOn, sendAction: .toggled)
    ///
    /// - Parameters:
    ///   - keyPath: A key path to the state value.
    ///   - action: The action to send on every value change.
    ///
    /// - Returns: A two-way binding backed by the reducer.
    public func binding<Value>(
        for keyPath: KeyPath<State, Value>,
        sendAction action: Action
    ) -> Binding<Value> {
        binding(for: keyPath, sendAction: { _ in action })
    }

    // MARK: - Auxiliary

    private func checkThreadPreconditions() {
        assert(
            Thread.isMainThread,
            "Must be called on main thread only"
        )
    }

    private func updateState(for action: Action) -> Effect<Action> {
        let oldState = internalState
        let effect = reducer.reduce(into: &internalState, action: action)
        if internalState != oldState { state = internalState }
        return effect
    }
}

@MainActor
public extension ViewModelOf {
    /// Sends an action and suspends until the state no longer
    /// satisfies the given predicate.
    ///
    /// This method dispatches the action, then observes published
    /// state changes until `predicate` returns `false`. It is
    /// commonly used to wait for a loading cycle to complete:
    ///
    ///     await viewModel.send(.refresh, while: \.isLoading)
    ///
    /// The effect's task is automatically cancelled if the calling
    /// task is cancelled, preventing orphaned work.
    ///
    /// - Parameters:
    ///   - action: The action to send.
    ///   - predicate: A closure evaluated against each new state.
    ///     The method returns when the predicate evaluates to
    ///     `false`.
    func send(
        _ action: Action,
        while predicate: @escaping (State) -> Bool
    ) async {
        let task = self.send(action)
        await withTaskCancellationHandler {
            await self.yield(while: predicate)
        } onCancel: {
            task.cancel()
        }
    }

    /// Sends an action with an animation and suspends until the
    /// state no longer satisfies the given predicate.
    ///
    /// - Parameters:
    ///   - action: The action to send.
    ///   - animation: The animation to apply to the state change.
    ///   - predicate: A closure evaluated against each new state.
    ///     The method returns when the predicate evaluates to
    ///     `false`.
    func send(
        _ action: Action,
        animation: Animation?,
        while predicate: @escaping (State) -> Bool
    ) async {
        let task = withAnimation(animation) { self.send(action) }
        await withTaskCancellationHandler {
            await self.yield(while: predicate)
        } onCancel: {
            task.cancel()
        }
    }

    /// Suspends until the state no longer satisfies the given
    /// predicate.
    ///
    /// This method observes the published ``state`` stream and
    /// returns as soon as `predicate` evaluates to `false`. Use it
    /// to wait for an arbitrary state condition without sending an
    /// action:
    ///
    ///     await viewModel.yield(while: \.isAnimating)
    ///
    /// - Parameter predicate: A closure evaluated against each new
    ///   state. The method returns when the predicate evaluates to
    ///   `false`.
    func yield(while predicate: @escaping (State) -> Bool) async {
        for await state in $state.values {
            if !predicate(state) { break }
        }
    }
}

@MainActor
public extension ViewModelOf {
    /// Subscribes this view model to an asynchronous sequence,
    /// mapping each element to an action.
    ///
    /// Each element the sequence produces is passed to `toAction`,
    /// and the resulting action is dispatched to the reducer on the
    /// main actor. Return `nil` from `toAction` to skip an element.
    ///
    /// Because this method returns `self`, subscriptions can be
    /// chained directly after the initializer:
    ///
    /// ```swift
    /// init(_ viewModel: ViewModel<SettingsReducer>) {
    ///     @SharedState(\.isLoggedIn) var isLoggedIn
    ///     @SharedEvent(\.sessionDidExpire) var sessionDidExpire
    ///
    ///     _viewModel = .init(
    ///         wrappedValue: viewModel
    ///             .observing($isLoggedIn.changes) { .isLoggedInChanged($0) }
    ///             .observing(sessionDidExpire.events) { _ in .sessionExpired }
    ///     )
    /// }
    /// ```
    ///
    /// The subscription task is retained by the view model and
    /// cancelled when the view model deinitializes – subscriptions
    /// live exactly as long as the view model.
    ///
    /// - Note: A ``StateStream/changes`` stream yields the current
    ///   value immediately upon subscription, so its mapped action
    ///   is dispatched once at creation time.
    ///
    /// - Parameters:
    ///   - source: The asynchronous sequence to observe.
    ///   - toAction: A closure that converts each element into an
    ///     action. Return `nil` to skip the element.
    ///
    /// - Returns: This view model, enabling chained `observing`
    ///   calls.
    @discardableResult
    func observing<S: AsyncSequence & Sendable>(
        _ source: S,
        _ toAction: @escaping @Sendable (S.Element) -> Action?
    ) -> Self where S.Element: Sendable, S.Failure == Never {
        observationTasks.append(
            Task { [weak self] in
                for await element in source {
                    guard let self else { return }
                    guard let action = toAction(element) else { continue }
                    send(action)
                }
            }
        )

        return self
    }
}

public extension ViewModelOf {
    /// Accesses the value at the given key path on the current
    /// state.
    ///
    /// Dynamic member lookup allows you to read state properties
    /// directly on the view model, removing the need to go through
    /// the ``state`` property explicitly:
    ///
    ///     viewModel.count  // equivalent to viewModel.state.count
    subscript<InnerValue>(dynamicMember keyPath: KeyPath<State, InnerValue>) -> InnerValue {
        state[keyPath: keyPath]
    }
}
