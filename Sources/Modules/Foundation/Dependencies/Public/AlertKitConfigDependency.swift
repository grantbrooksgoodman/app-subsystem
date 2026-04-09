//
//  AlertKitConfigDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/* Proprietary */
import AlertKit

public enum AlertKitConfigDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> AlertKit.Config {
        @MainActorIsolated var config = AlertKit.Config.shared
        return config
    }
}

public extension DependencyValues {
    var alertKitConfig: AlertKit.Config {
        get { self[AlertKitConfigDependency.self] }
        set { self[AlertKitConfigDependency.self] = newValue }
    }
}
