//
//  AppThemeListDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension AppSubsystem.Delegates {
    protocol AppThemeListDelegate {
        var allAppThemes: [AppTheme] { get }
    }

    struct DefaultAppThemeListDelegate: AppThemeListDelegate {
        public var allAppThemes: [AppTheme] {
            [
                .default,
            ]
        }
    }
}
