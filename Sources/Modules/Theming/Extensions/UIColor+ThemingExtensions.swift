//
//  UIColor+ThemingExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

public extension UIColor {
    static var accent: UIColor { theme.color(for: .accent) }
    static var background: UIColor { theme.color(for: .background) }
    static var disabled: UIColor { theme.color(for: .disabled) }
    static var groupedContentBackground: UIColor { theme.color(for: .groupedContentBackground) }

    static var navigationBarBackground: UIColor { theme.color(for: .navigationBarBackground) }
    static var navigationBarTitle: UIColor { theme.color(for: .navigationBarTitle) }

    static var subtitleText: UIColor { theme.color(for: .subtitleText) }
    static var titleText: UIColor { theme.color(for: .titleText) }

    private static var theme: UITheme { ThemeService.currentTheme }
}
