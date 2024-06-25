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

public typealias ViewModel<R> = ViewModelOf<R.State, R.Action, R.Feedback> where R: Reducer

@MainActor
@dynamicMemberLookup
public final class ViewModelOf<State: Equatable, Action, Feedback>: ObservableObject {
    // MARK: - Properties

    @Published public private(set) var state: State

    private let reducer: any Reducer<State, Action, Feedback>
    private var internalState: State
    private var parentCancellable: AnyCancellable?
    private var _isInvalidated = { false }

    // MARK: - Init

    public init(
        initialState: State,
        reducer: any Reducer<State, Action, Feedback>
    ) {
        self.state = initialState
        self.internalState = initialState
        self.reducer = reducer
    }

    // MARK: - Send

    @discardableResult
    public func send(_ action: Action) -> Task<Void, Never> {
        self.send(.action(action))
    }

    @discardableResult
    public func send(_ action: Action, animation: Animation?) -> Task<Void, Never> {
        send(action, transaction: Transaction(animation: animation))
    }

    @discardableResult
    public func send(_ action: Action, transaction: Transaction) -> Task<Void, Never> {
        withTransaction(transaction) {
            self.send(.action(action))
        }
    }

    @discardableResult
    private func send(_ event: ReduceEvent<Action, Feedback>) -> Task<Void, Never> {
        checkThreadPreconditions()
        guard !_isInvalidated() else { return Task {} }

        let effect = updateState(for: event)
        return Task(priority: effect.priority) { [weak self] in
            await effect.operation(
                Send { [weak self] feedback in
                    self?.send(.feedback(feedback))
                }
            )
        }
    }

    // MARK: - Cancellable

    public func sendCancellableAction(_ action: Action) async {
        let task = send(action)
        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
    }

    private func sendCancellableFeedback(_ feedback: Feedback) async {
        let task = send(.feedback(feedback))
        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
    }

    // MARK: - Binding for Key Path

    public func binding<Value>(
        for keyPath: KeyPath<State, Value>,
        sendAction valueToAction: @escaping (Value) -> Action
    ) -> Binding<Value> {
        Binding<Value>(
            get: { self.state[keyPath: keyPath] },
            set: { value in
                let action = valueToAction(value)
                self.send(.action(action))
            }
        )
    }

    public func binding<Value>(
        for keyPath: KeyPath<State, Value>,
        sendAction valueToAction: @escaping (Value) -> Action?
    ) -> Binding<Value> {
        Binding<Value>(
            get: { self.state[keyPath: keyPath] },
            set: { value in
                if let action = valueToAction(value) {
                    self.send(.action(action))
                }
            }
        )
    }

    public func binding<Value>(
        for keyPath: KeyPath<State, Value>,
        sendAction action: Action
    ) -> Binding<Value> {
        binding(for: keyPath, sendAction: { _ in action })
    }

    // MARK: - Auxiliary

    private func checkThreadPreconditions() { assert(Thread.isMainThread, "Must be called on main thread only") }

    private func updateState(for event: ReduceEvent<Action, Feedback>) -> Effect<Feedback> {
        let oldState = internalState
        let effect = reducer.reduce(into: &internalState, for: event)
        if internalState != oldState { state = internalState }
        return effect
    }
}

public extension ViewModelOf {
    @MainActor
    func send(_ action: Action, while predicate: @escaping (State) -> Bool) async {
        let task = self.send(.action(action))
        await withTaskCancellationHandler {
            await self.yield(while: predicate)
        } onCancel: {
            task.cancel()
        }
    }

    @MainActor
    func send(
        _ action: Action,
        animation: Animation?,
        while predicate: @escaping (State) -> Bool
    ) async {
        let task = withAnimation(animation) { self.send(.action(action)) }
        await withTaskCancellationHandler {
            await self.yield(while: predicate)
        } onCancel: {
            task.cancel()
        }
    }

    @MainActor
    func yield(while predicate: @escaping (State) -> Bool) async {
        _ = await $state
            .values
            .first(where: { !predicate($0) })
    }
}

public extension ViewModelOf {
    func derived<DerivedState: Equatable, DerivedAction, DerivedFeedback>(
        from toState: @escaping (State) -> DerivedState,
        action toAction: @escaping (DerivedAction) -> Action,
        feedback toFeedback: @escaping (DerivedFeedback) -> Feedback,
        isDuplicate: ((DerivedState, DerivedState) -> Bool)? = nil,
        isInvalid: ((State) -> Bool)? = nil
    ) -> ViewModelOf<DerivedState, DerivedAction, DerivedFeedback> {
        let reducer = Reduce<DerivedState, DerivedAction, DerivedFeedback> { _, event in
            switch event {
            case let .action(derivedAction):
                return .fireAndForget {
                    await self.sendCancellableAction(toAction(derivedAction))
                }

            case let .feedback(derivedFeedback):
                return .fireAndForget {
                    await self.sendCancellableFeedback(toFeedback(derivedFeedback))
                }
            }
        }

        let derivedViewModel = ViewModelOf<DerivedState, DerivedAction, DerivedFeedback>(
            initialState: toState(state),
            reducer: reducer
        )

        derivedViewModel.parentCancellable = $state.dropFirst()
            .filter { !(isInvalid?($0) == true || self._isInvalidated()) }
            .map(toState)
            .removeDuplicates(by: isDuplicate ?? { $0 == $1 })
            .sink { [weak derivedViewModel] newValue in
                derivedViewModel?.state = newValue
            }

        derivedViewModel._isInvalidated = { [weak self] in
            guard let self else { return true }
            return isInvalid?(self.state) == true || self._isInvalidated()
        }

        return derivedViewModel
    }

    func derived<DerivedState: Equatable>(
        from toState: @escaping (State) -> DerivedState
    ) -> ViewModelOf<DerivedState, Action, Feedback> {
        self.derived(from: toState, action: { $0 }, feedback: { $0 })
    }

    func derived<DerivedState: Equatable, DerivedAction>(
        from toState: @escaping (State) -> DerivedState,
        action toAction: @escaping (DerivedAction) -> Action
    ) -> ViewModelOf<DerivedState, DerivedAction, Feedback> {
        self.derived(from: toState, action: toAction, feedback: { $0 })
    }
}

public extension ViewModelOf {
    subscript<InnerValue>(dynamicMember keyPath: KeyPath<State, InnerValue>) -> InnerValue { state[keyPath: keyPath] }
}
