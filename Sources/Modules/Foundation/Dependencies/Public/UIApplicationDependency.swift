//
//  UIApplicationDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

public enum UIApplicationDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> UIApplication {
        .shared
    }
}

public extension DependencyValues {
    var uiApplication: UIApplication {
        get { self[UIApplicationDependency.self] }
        set { self[UIApplicationDependency.self] = newValue }
    }
}
