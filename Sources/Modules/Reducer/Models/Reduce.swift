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
/// declaring a dedicated type.
///
/// For standalone features, prefer conforming directly to ``Reducer``
/// instead – the explicit type makes the feature easier to find,
/// reference, and test.
///
/// - SeeAlso: ``Reducer``, ``ReducerBuilder``
public struct Reduce<State: Equatable, Action>: Reducer {
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
