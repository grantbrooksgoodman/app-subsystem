//
//  LocalizationSource.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A value that identifies the property list and bundle from
/// which localized strings are resolved.
///
/// Use `LocalizationSource` to specify which property list and
/// bundle the localization system reads from when resolving a
/// string key. AppSubsystem maintains its own localized strings
/// property list, separate from the app's. Apps that use
/// AppSubsystem do not need to include the subsystem's keys in
/// their own property lists.
///
/// Each case identifies a distinct property list:
///
/// - ``app(plistName:)`` reads from the main bundle. The
///   property list name defaults to `LocalizedStrings`.
/// - ``custom(bundle:plistName:)`` reads from an arbitrary
///   property list in an arbitrary bundle.
/// - ``subsystem`` reads from AppSubsystem's own
///   `LocalizedStrings` property list, bundled within the
///   AppSubsystem module.
///
/// In most cases, pass ``app()`` to resolve strings from the
/// app's property list. The ``subsystem`` source is used
/// primarily by AppSubsystem itself, but apps can also pass it
/// to resolve the subsystem's built-in strings. For the full
/// list of available keys, see ``SubsystemStringKey``.
///
/// - SeeAlso: ``Localized``, ``LocalizedStringKeyRepresentable``
public enum LocalizationSource: Hashable {
    // MARK: - Cases

    /// Reads from the main bundle. The property list name defaults
    /// to `LocalizedStrings`.
    case app(plistName: String = "LocalizedStrings")

    /// Reads from an arbitrary property list in an arbitrary bundle.
    case custom(
        bundle: Bundle = .main,
        plistName: String
    )

    /// Reads from AppSubsystem's own `LocalizedStrings`
    /// property list, bundled within the AppSubsystem module.
    case subsystem

    // MARK: - Properties

    var bundle: Bundle {
        switch self {
        case .app: .main
        case let .custom(bundle: bundle, plistName: _): bundle
        case .subsystem: .module
        }
    }

    var plistName: String {
        switch self {
        case let .app(plistName: plistName): plistName
        case let .custom(bundle: _, plistName: plistName): plistName
        case .subsystem: "LocalizedStrings"
        }
    }
}
