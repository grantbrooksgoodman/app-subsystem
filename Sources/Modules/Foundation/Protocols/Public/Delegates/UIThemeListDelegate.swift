//
//  UIThemeListDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension AppSubsystem.Delegates {
    /// A type that provides the list of app-defined UI themes.
    ///
    /// Conform to this protocol to register custom themes with the
    /// subsystem. The themes you return from ``uiThemes`` are merged
    /// with the subsystem's built-in themes and made available through
    /// ``UITheme/allCases``:
    ///
    /// ```swift
    /// struct AppUIThemeList: AppSubsystem.Delegates.UIThemeListDelegate {
    ///     let uiThemes: [UITheme] = [
    ///         .ocean,
    ///         .sunset,
    ///     ]
    /// }
    /// ```
    ///
    /// If you do not provide a custom conformance, the subsystem uses
    /// ``DefaultUIThemeListDelegate``, which includes only the
    /// built-in themes.
    ///
    /// - SeeAlso: ``UITheme``
    protocol UIThemeListDelegate {
        /// The app-defined themes to register with the
        /// subsystem.
        ///
        /// These themes are combined with the subsystem's built-in
        /// themes. Duplicate entries are removed automatically.
        var uiThemes: [UITheme] { get }
    }

    /// The default UI theme list delegate, which includes only the
    /// subsystem's built-in themes.
    struct DefaultUIThemeListDelegate: UIThemeListDelegate {
        public let uiThemes = UITheme.subsystemCases
    }
}
