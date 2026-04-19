//
//  Effect+Merge.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension Effect {
    /// Combines the given effects into a single effect that runs them all
    /// in parallel.
    ///
    /// Use `merge` when a single action should trigger multiple
    /// independent pieces of work:
    ///
    /// ```swift
    /// return .merge(
    ///    .fireAndForget { await analytics.track(.refreshed) },
    ///    .task { await .itemsLoaded(service.fetchItems()) }
    /// )
    /// ```
    ///
    /// All merged effects share a single ``Send`` callback. Actions sent
    /// by any of the effects are delivered in the order they arrive.
    ///
    /// - Parameter effects: The effects to run in parallel.
    ///
    /// - Returns: A single effect that runs all provided effects
    ///   concurrently.
    static func merge(_ effects: Self...) -> Self {
        merge(effects)
    }

    /// Combines a sequence of effects into a single effect that runs them
    /// all in parallel.
    ///
    /// - Parameter effects: A sequence of effects to run in parallel.
    ///
    /// - Returns: A single effect that runs all provided effects
    ///   concurrently.
    static func merge(_ effects: some Sequence<Self>) -> Self {
        effects.reduce(.none) { $0.merge(with: $1) }
    }

    /// Combines this effect with another, running both in parallel.
    ///
    /// - Parameter other: The effect to run alongside this one.
    ///
    /// - Returns: A single effect that runs both effects concurrently.
    func merge(with other: Self) -> Self {
        .run { send in
            await withTaskGroup(of: Void.self) { group in
                group.addTask(priority: priority) {
                    await self.operation(send)
                }

                group.addTask(priority: other.priority) {
                    await other.operation(send)
                }
            }
        }
    }
}
