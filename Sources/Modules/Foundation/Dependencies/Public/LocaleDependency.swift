//
//  LocaleDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// The dependency key that provides a ``Locale`` instance.
public enum LocaleDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> Locale {
        .current
    }
}

public extension DependencyValues {
    /// The shared ``Locale`` instance.
    var currentLocale: Locale {
        get { self[LocaleDependency.self] }
        set { self[LocaleDependency.self] = newValue }
    }
}
