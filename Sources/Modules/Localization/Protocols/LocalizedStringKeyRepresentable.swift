//
//  LocalizedStringKeyRepresentable.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A type whose values identify entries in the localized strings file.
///
/// Conform to `LocalizedStringKeyRepresentable` to define a set of
/// localization keys that can be used with the ``Localized`` property
/// wrapper. Conforming types are typically enums whose cases correspond
/// to top-level keys in `LocalizedStrings.plist`:
///
/// ```swift
/// enum StringKey: String, LocalizedStringKeyRepresentable {
///    case greeting
///    case farewell
///
///    var referent: String { rawValue }
/// }
/// ```
///
/// The ``referent`` property returns the string used to look up the
/// localized value in the property list. In most cases, returning `rawValue` is
/// sufficient.
public protocol LocalizedStringKeyRepresentable: RawRepresentable, Equatable {
    /// The key used to look up the localized string in
    /// `LocalizedStrings.plist`.
    var referent: String { get }
}
