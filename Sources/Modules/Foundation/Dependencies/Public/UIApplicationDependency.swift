//
//  UIApplicationDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

/// The dependency key that provides a ``UIApplication`` instance.
public enum UIApplicationDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> UIApplication {
        @MainActorIsolated var uiApplication = UIApplication.shared
        return uiApplication
    }
}

public extension DependencyValues {
    /// The shared ``UIApplication`` instance.
    var uiApplication: UIApplication {
        get { self[UIApplicationDependency.self] }
        set { self[UIApplicationDependency.self] = newValue }
    }
}
