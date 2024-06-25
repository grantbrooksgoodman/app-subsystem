//
//  Reducer.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public protocol Reducer<State, Action, Feedback> {
    // MARK: - Associated Types

    associatedtype Action
    associatedtype Feedback
    associatedtype ReducerBody
    associatedtype State: Equatable

    // MARK: - Type Aliases

    typealias Event = ReduceEvent<Action, Feedback>

    // MARK: - Properties

    @ReducerBuilder<State, Action, Feedback> var body: ReducerBody { get }

    // MARK: - Methods

    func reduce(
        into state: inout State,
        for event: Event
    ) -> Effect<Feedback>
}

public extension Reducer where ReducerBody == Never {
    var body: ReducerBody { fatalError("Body may not be called directly") }
}
