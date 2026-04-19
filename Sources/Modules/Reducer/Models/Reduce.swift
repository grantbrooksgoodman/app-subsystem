//
//  Reduce.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A reducer that wraps a closure.
///
/// Use `Reduce` when you want to express a reducer inline without
/// declaring a dedicated type. This is useful when composing reducers in
/// a ``Reducer/ReducerBody`` implementation:
///
/// ```swift
/// var body: some Reducer<State, Action> {
///    Reduce { state, action in
///        switch action {
///        case .increment:
///            state.count += 1
///            return .none
///        }
///    }
/// }
/// ```
///
/// For standalone features, prefer conforming directly to ``Reducer``
/// instead – the explicit type makes the feature easier to find,
/// reference, and test.
///
/// - SeeAlso: ``Reducer``, ``ReducerBuilder``
public struct Reduce<State, Action>: Reducer where State: Equatable {
    // MARK: - Properties

    let reduce: (inout State, Action) -> Effect<Action>

    // MARK: - Init

    /// Creates a reducer from the given closure.
    ///
    /// - Parameter reduce: A closure that takes the current state and an
    ///   action, mutates the state, and returns an ``Effect``.
    public init(reduce: @escaping (inout State, Action) -> Effect<Action>) {
        self.reduce = reduce
    }

    // MARK: - Reduce

    public func reduce(
        into state: inout State,
        action: Action
    ) -> Effect<Action> {
        reduce(&state, action)
    }
}
