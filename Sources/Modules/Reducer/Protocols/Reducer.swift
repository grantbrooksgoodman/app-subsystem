//
//  Reducer.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public protocol Reducer<State, Action> {
    // MARK: - Associated Types

    associatedtype Action
    associatedtype ReducerBody
    associatedtype State: Equatable

    // MARK: - Properties

    @ReducerBuilder<State, Action> var body: ReducerBody { get }

    // MARK: - Methods

    func reduce(
        into state: inout State,
        action: Action
    ) -> Effect<Action>
}

public extension Reducer where ReducerBody == Never {
    var body: ReducerBody { fatalError("Body may not be called directly") }
}
