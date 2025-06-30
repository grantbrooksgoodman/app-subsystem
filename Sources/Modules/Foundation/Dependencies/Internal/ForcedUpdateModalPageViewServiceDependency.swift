//
//  ForcedUpdateModalPageViewServiceDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

enum ForcedUpdateModalPageViewServiceDependency: DependencyKey {
    static func resolve(_: DependencyValues) -> ForcedUpdateModalPageViewService {
        .init()
    }
}

extension DependencyValues {
    var forcedUpdateModalPageViewService: ForcedUpdateModalPageViewService {
        get { self[ForcedUpdateModalPageViewServiceDependency.self] }
        set { self[ForcedUpdateModalPageViewServiceDependency.self] = newValue }
    }
}
