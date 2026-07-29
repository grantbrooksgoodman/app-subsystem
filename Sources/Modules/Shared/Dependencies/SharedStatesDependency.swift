//
//  SharedStatesDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

enum SharedStatesDependency: DependencyKey {
    static func resolve(_: DependencyValues) -> SharedStates {
        .init()
    }
}

extension DependencyValues {
    /// Intentionally internal: shared state is accessible outside the
    /// module only through the @SharedState property wrapper.
    var sharedStates: SharedStates {
        self[SharedStatesDependency.self]
    }
}
