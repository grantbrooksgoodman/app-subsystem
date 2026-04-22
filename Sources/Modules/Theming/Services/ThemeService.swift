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

/// The central point of control for the app's active theme.
///
/// Use `ThemeService` to read the current theme, apply a new one, or
/// query the active appearance:
///
/// ```swift
/// // Apply a theme.
/// ThemeService.setTheme(oceanTheme)
///
/// // Read the active theme.
/// let accent = ThemeService.currentTheme.color(for: .accent)
///
/// // Check dark mode.
/// if ThemeService.isDarkModeActive { ... }
/// ```
///
/// When a new theme is applied, the service persists the selection,
/// updates the interface style, and triggers the
/// `Observables.themedViewAppearanceChanged` observable so that all
/// ``ThemedView`` instances update with the new colors.
///
/// ## Style Changes
///
/// If the new theme requires a different interface style than the one
/// currently in use (for example, switching from a light-only theme to a
/// dark-only theme), the change is deferred until the next app
/// launch, and the user is presented with an alert explaining that a restart
/// is required. The pending theme is persisted and applied automatically
/// the next time ``AppSubsystem`` initializes.
@MainActor
public enum ThemeService {
    // MARK: - Properties

    /// The currently active theme.
    ///
    /// Setting this property persists the new theme, applies its interface
    /// style, and notifies all themed views of the change.
    public private(set) static var currentTheme = UITheme.default {
        didSet {
            @Persistent(.currentThemeID) var currentThemeID: String?
            currentThemeID = currentTheme.encodedHash

            setStyle()
            Observables.themedViewAppearanceChanged.trigger()
        }
    }

    // MARK: - Computed Properties

    /// A Boolean value that indicates whether dark mode is currently active.
    ///
    /// This property accounts for both the theme's explicit interface style
    /// and the system appearance setting.
    public static var isDarkModeActive: Bool {
        @Dependency(\.uiApplication) var uiApplication: UIApplication
        let appliedInterfaceStyle = (uiApplication.interfaceStyle ?? currentTheme.style)
        let currentInterfaceStyle = (uiApplication.mainWindow?.traitCollection.userInterfaceStyle ?? UITraitCollection.current.userInterfaceStyle)
        return (appliedInterfaceStyle == .unspecified ? currentInterfaceStyle : appliedInterfaceStyle) == .dark
    }

    /// A Boolean value that indicates whether the built-in default theme is
    /// currently active.
    public static var isDefaultThemeApplied: Bool { currentTheme == UITheme.default }

    // MARK: - Set Theme

    /// Applies the given theme to the app.
    ///
    /// When `checkStyle` is `true` (the default), the method compares the
    /// new theme's interface style against the current theme's style. If
    /// they differ, the theme is saved as pending and an alert informs the
    /// user that a restart is required. Themes with a matching style are
    /// applied immediately.
    ///
    /// Pass `false` for `checkStyle` to apply the theme unconditionally.
    /// This is used internally during initialization to restore a persisted
    /// theme without presenting an alert.
    ///
    /// - Parameters:
    ///   - theme: The theme to apply.
    ///   - checkStyle: Whether to verify that the new theme's interface
    ///     style matches the current one. Defaults to `true`.
    public static func setTheme(
        _ theme: UITheme,
        checkStyle: Bool = true
    ) {
        @Persistent(.pendingThemeID) var pendingThemeID: String?

        guard checkStyle else {
            pendingThemeID = nil
            return currentTheme = theme
        }

        if currentTheme.style != theme.style {
            Task { @MainActor in
                await AKAlert(
                    message: "The new appearance will take effect the next time you restart the app."
                ).present()
            }

            return pendingThemeID = theme.encodedHash
        }

        pendingThemeID = nil
        currentTheme = theme
    }

    // MARK: - Auxiliary

    private static func setStyle() {
        @Dependency(\.coreKit.ui) var coreUI: CoreKit.UI
        @Dependency(\.uiApplication) var uiApplication: UIApplication

        guard uiApplication.applicationState == .active else {
            Task.delayed(by: .milliseconds(10)) { @MainActor in
                setStyle()
            }
            return
        }

        let currentThemeStyle = currentTheme.style
        guard uiApplication.interfaceStyle != currentThemeStyle else { return }
        coreUI.overrideUserInterfaceStyle(currentThemeStyle)
    }
}
