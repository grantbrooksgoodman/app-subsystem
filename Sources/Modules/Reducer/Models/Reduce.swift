//
//  Reduce.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public struct Reduce<State, Action, Feedback>: Reducer where State: Equatable {
    // MARK: - Properties

    let reduce: (inout State, ReduceEvent<Action, Feedback>) -> Effect<Feedback>

    // MARK: - Init

    public init(reduce: @escaping (inout State, ReduceEvent<Action, Feedback>) -> Effect<Feedback>) {
        self.reduce = reduce
    }

    // MARK: - Reduce

    public func reduce(
        into state: inout State,
        for event: ReduceEvent<Action, Feedback>
    ) -> Effect<Feedback> {
        reduce(&state, event)
    }
}
