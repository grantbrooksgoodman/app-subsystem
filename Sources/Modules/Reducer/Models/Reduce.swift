//
//  Reduce.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public struct Reduce<State, Action>: Reducer where State: Equatable {
    // MARK: - Properties

    let reduce: (inout State, Action) -> Effect<Action>

    // MARK: - Init

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
