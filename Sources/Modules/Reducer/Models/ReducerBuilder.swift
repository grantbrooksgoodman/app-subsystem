//
//  ReducerBuilder.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A result builder that composes multiple reducers that share the same
/// state and action types.
///
/// `ReducerBuilder` powers the ``Reducer/ReducerBody`` property,
/// allowing you to list child reducers declaratively:
///
/// ```swift
/// var body: some Reducer<State, Action> {
///     ChildReducerA()
///     ChildReducerB()
/// }
/// ```
///
/// Each child reducer is called in order for every action. Their effects
/// are collected and run together.
///
/// You do not use this type directly. It is applied automatically through
/// the `@ReducerBuilder` attribute on ``Reducer/ReducerBody``.
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
