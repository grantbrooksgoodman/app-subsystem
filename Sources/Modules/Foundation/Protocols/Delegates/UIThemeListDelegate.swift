//
//  UIThemeListDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension AppSubsystem.Delegates {
    protocol UIThemeListDelegate {
        var uiThemes: [UITheme] { get }
    }

    struct DefaultUIThemeListDelegate: UIThemeListDelegate {
        public let uiThemes = UITheme.subsystemCases
    }
}
