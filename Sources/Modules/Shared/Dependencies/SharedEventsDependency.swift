//
//  SharedEventsDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

enum SharedEventsDependency: DependencyKey {
    static func resolve(_: DependencyValues) -> SharedEvents {
        .init()
    }
}

extension DependencyValues {
    /// Intentionally internal: shared events are accessible outside the
    /// module only through the @SharedEvent property wrapper.
    var sharedEvents: SharedEvents {
        self[SharedEventsDependency.self]
    }
}
