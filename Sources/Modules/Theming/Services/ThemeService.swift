//
//  ThemeService.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

/* Proprietary */
import AlertKit

public enum ThemeService {
    // MARK: - Properties

    public private(set) static var currentTheme = UITheme.default {
        didSet {
            @Persistent(.currentThemeID) var currentThemeID: String?
            currentThemeID = currentTheme.encodedHash

            setStyle()
            Observables.themedViewAppearanceChanged.trigger()
        }
    }

    // MARK: - Computed Properties

    public static var isDarkModeActive: Bool {
        @Dependency(\.uiApplication) var uiApplication: UIApplication
        let appliedInterfaceStyle = (uiApplication.interfaceStyle ?? currentTheme.style)
        let currentInterfaceStyle = (uiApplication.mainWindow?.traitCollection.userInterfaceStyle ?? UITraitCollection.current.userInterfaceStyle)
        return (appliedInterfaceStyle == .unspecified ? currentInterfaceStyle : appliedInterfaceStyle) == .dark
    }

    public static var isDefaultThemeApplied: Bool { currentTheme == UITheme.default }

    // MARK: - Set Theme

    public static func setTheme(_ theme: UITheme, checkStyle: Bool = true) {
        Task { @MainActor in
            @Persistent(.pendingThemeID) var pendingThemeID: String?

            guard checkStyle else { return currentTheme = theme }
            guard currentTheme.style == theme.style else {
                await AKAlert(
                    message: "The new appearance will take effect the next time you restart the app."
                ).present()
                return pendingThemeID = theme.encodedHash
            }

            pendingThemeID = nil
            currentTheme = theme
        }
    }

    // MARK: - Auxiliary

    private static func setStyle() {
        @Dependency(\.coreKit) var core: CoreKit
        @Dependency(\.uiApplication) var uiApplication: UIApplication

        guard uiApplication.applicationState == .active else {
            return core.gcd.after(.milliseconds(10)) { self.setStyle() }
        }

        let currentThemeStyle = currentTheme.style
        guard uiApplication.interfaceStyle != currentThemeStyle else { return }
        core.ui.overrideUserInterfaceStyle(currentThemeStyle)
    }
}
