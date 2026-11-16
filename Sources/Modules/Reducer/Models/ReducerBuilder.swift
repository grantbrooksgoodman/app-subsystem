//
//  ReducerBuilder.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A result builder for reducers that share the same state and action
/// types.
///
/// You do not use this type directly. It is applied automatically through
/// the `@ReducerBuilder` attribute on ``Reducer/body``.
@resultBuilder
public enum ReducerBuilder<State: Equatable, Action> {
    // MARK: - Build Block

    public static func buildBlock<R: Reducer>(_ components: R...) -> [R] where R.State == State, R.Action == Action {
        components
    }

    // MARK: - Build Partial Block

    public static func buildPartialBlock<R: Reducer>(first: R) -> R where R.State == State, R.Action == Action {
        first
    }
}
