//
//  Effect+Merge.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension Effect {
    static func merge(_ effects: Self...) -> Self {
        merge(effects)
    }

    static func merge(_ effects: some Sequence<Self>) -> Self {
        effects.reduce(.none) { $0.merge(with: $1) }
    }

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
