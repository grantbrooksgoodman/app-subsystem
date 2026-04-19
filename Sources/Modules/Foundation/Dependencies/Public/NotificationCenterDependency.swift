//
//  NotificationCenterDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// The dependency key that provides a ``NotificationCenter`` instance.
public enum NotificationCenterDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> NotificationCenter {
        .default
    }
}

public extension DependencyValues {
    /// The shared ``NotificationCenter`` instance.
    var notificationCenter: NotificationCenter {
        get { self[NotificationCenterDependency.self] }
        set { self[NotificationCenterDependency.self] = newValue }
    }
}
