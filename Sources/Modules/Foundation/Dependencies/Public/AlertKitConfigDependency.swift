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

/// The dependency key that provides an ``AlertKit/Config`` instance.
public enum AlertKitConfigDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> AlertKit.Config {
        @MainActorIsolated var alertKitConfig = AlertKit.config
        return alertKitConfig
    }
}

public extension DependencyValues {
    /// The shared ``AlertKit/Config`` instance.
    var alertKitConfig: AlertKit.Config {
        get { self[AlertKitConfigDependency.self] }
        set { self[AlertKitConfigDependency.self] = newValue }
    }
}
