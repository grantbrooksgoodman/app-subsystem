//
//  MainBundleDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// The dependency key that provides a ``Bundle`` instance.
public enum MainBundleDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> Bundle {
        .main
    }
}

public extension DependencyValues {
    /// The shared ``Bundle`` instance.
    var mainBundle: Bundle {
        get { self[MainBundleDependency.self] }
        set { self[MainBundleDependency.self] = newValue }
    }
}
