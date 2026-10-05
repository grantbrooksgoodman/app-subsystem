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
        // swiftformat:disable all
        @MainActorIsolated var alertKitConfig = AlertKit.config
        return alertKitConfig // swiftformat:enable all
    }
}

public extension DependencyValues {
    /// The shared ``AlertKit/Config`` instance.
    var alertKitConfig: AlertKit.Config {
        get { self[AlertKitConfigDependency.self] }
        set { self[AlertKitConfigDependency.self] = newValue }
    }
}
