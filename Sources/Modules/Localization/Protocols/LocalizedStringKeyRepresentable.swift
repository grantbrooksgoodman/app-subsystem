//
//  LocalizedStringKeyRepresentable.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A type whose values identify entries in a localized strings
/// property list.
///
/// Conform to `LocalizedStringKeyRepresentable` to define a set
/// of localization keys that can be used with the ``Localized``
/// property wrapper. Conforming types are typically enums whose
/// cases correspond to top-level keys in a localized strings
/// property list:
///
/// ```swift
/// enum StringKey: String, LocalizedStringKeyRepresentable {
///     case greeting
///     case farewell
///
///     var referent: String { rawValue }
/// }
/// ```
///
/// The ``referent`` property returns the string used to look up
/// the localized value. In most cases, returning `rawValue` is
/// sufficient.
///
/// - SeeAlso: ``Localized``, ``LocalizationSource``
public protocol LocalizedStringKeyRepresentable: RawRepresentable, Equatable {
    /// The key used to look up the localized string in the
    /// property list.
    var referent: String { get }
}
