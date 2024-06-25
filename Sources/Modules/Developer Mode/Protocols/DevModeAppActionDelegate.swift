//
//  DevModeAppActionDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension AppSubsystem.Delegates {
    protocol DevModeAppActionDelegate {
        var appActions: [DevModeAction] { get }
    }
}
