//
//  BuildInfoOverlayViewServiceDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

enum BuildInfoOverlayViewServiceDependency: DependencyKey {
    static func resolve(_: DependencyValues) -> BuildInfoOverlayViewService {
        .init()
    }
}

extension DependencyValues {
    var buildInfoOverlayViewService: BuildInfoOverlayViewService {
        get { self[BuildInfoOverlayViewServiceDependency.self] }
        set { self[BuildInfoOverlayViewServiceDependency.self] = newValue }
    }
}
