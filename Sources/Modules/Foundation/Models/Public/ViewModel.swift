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

public typealias ViewModel<R> = ViewModelOf<R.State, R.Action> where R: Reducer

@MainActor
@dynamicMemberLookup
public final class ViewModelOf<State: Equatable, Action>: ObservableObject {
    // MARK: - Properties

    @Published public private(set) var state: State

    private let reducer: any Reducer<State, Action>
    private var internalState: State
    private var parentCancellable: AnyCancellable?
    private var _isInvalidated = { false }

    // MARK: - Init

    public init(
        initialState: State,
        reducer: any Reducer<State, Action>
    ) {
        self.state = initialState
        self.internalState = initialState
        self.reducer = reducer
    }

    // MARK: - Send

    @discardableResult
    public func send(_ action: Action) -> Task<Void, Never> {
        self._send(action)
    }

    @discardableResult
    public func send(_ action: Action, animation: Animation?) -> Task<Void, Never> {
        send(action, transaction: Transaction(animation: animation))
    }

    @discardableResult
    public func send(_ action: Action, transaction: Transaction) -> Task<Void, Never> {
        withTransaction(transaction) {
            self._send(action)
        }
    }

    @discardableResult
    private func _send(_ action: Action) -> Task<Void, Never> {
        checkThreadPreconditions()
        guard !_isInvalidated() else { return Task {} }

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

    public func sendCancellableAction(_ action: Action) async {
        let task = send(action)
        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
    }

    // MARK: - Binding for Key Path

    public func binding<Value>(for keyPath: KeyPath<State, Value>) -> Binding<Value> {
        binding(for: keyPath, sendAction: { _ in .none })
    }

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

    public func binding<Value>(
        for keyPath: KeyPath<State, Value>,
        sendAction action: Action
    ) -> Binding<Value> {
        binding(for: keyPath, sendAction: { _ in action })
    }

    // MARK: - Auxiliary

    private func checkThreadPreconditions() { assert(Thread.isMainThread, "Must be called on main thread only") }

    private func updateState(for action: Action) -> Effect<Action> {
        let oldState = internalState
        let effect = reducer.reduce(into: &internalState, action: action)
        if internalState != oldState { state = internalState }
        return effect
    }
}

public extension ViewModelOf {
    @MainActor
    func send(_ action: Action, while predicate: @escaping (State) -> Bool) async {
        let task = self.send(action)
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
        let task = withAnimation(animation) { self.send(action) }
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
    subscript<InnerValue>(dynamicMember keyPath: KeyPath<State, InnerValue>) -> InnerValue { state[keyPath: keyPath] }
}
