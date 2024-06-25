//
//  ReducerBuilder.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

@resultBuilder
public enum ReducerBuilder<State, Action> where State: Equatable {
    // MARK: - Build Block

    public static func buildBlock<R>(_ components: R...) -> [R] where R: Reducer, R.State == State, R.Action == Action {
        components
    }

    // MARK: - Build Partial Block

    public static func buildPartialBlock<R>(first: R) -> R where R: Reducer, R.State == State, R.Action == Action {
        first
    }
}
