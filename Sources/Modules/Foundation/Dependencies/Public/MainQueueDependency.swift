//
//  MainQueueDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// The dependency key that provides a ``DispatchQueue`` instance.
public enum MainQueueDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> DispatchQueue {
        .main
    }
}

public extension DependencyValues {
    /// The shared ``DispatchQueue`` instance.
    var mainQueue: DispatchQueue {
        get { self[MainQueueDependency.self] }
        set { self[MainQueueDependency.self] = newValue }
    }
}
