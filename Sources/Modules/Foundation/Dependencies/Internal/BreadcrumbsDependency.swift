//
//  BreadcrumbsDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

enum BreadcrumbsDependency: DependencyKey {
    static func resolve(_: DependencyValues) -> Breadcrumbs {
        .init()
    }
}

extension DependencyValues {
    var breadcrumbs: Breadcrumbs {
        get { self[BreadcrumbsDependency.self] }
        set { self[BreadcrumbsDependency.self] = newValue }
    }
}
