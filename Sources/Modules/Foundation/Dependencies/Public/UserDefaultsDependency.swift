//
//  UserDefaultsDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// The dependency key that provides a ``UserDefaults`` instance.
public enum UserDefaultsDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> UserDefaults {
        .standard
    }
}

public extension DependencyValues {
    /// The shared ``UserDefaults`` instance.
    var userDefaults: UserDefaults {
        get { self[UserDefaultsDependency.self] }
        set { self[UserDefaultsDependency.self] = newValue }
    }
}
