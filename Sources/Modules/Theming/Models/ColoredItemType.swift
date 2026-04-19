//
//  ColoredItemType.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// An identifier for a semantic color slot within a ``UITheme``.
///
/// Colored item types act as keys that map a design concept – such as
/// "accent" or "background" – to a concrete color in the active theme.
/// The framework provides a set of built-in types. Define additional types
/// as static properties in an extension to represent app-specific colors:
///
/// ```swift
/// public extension ColoredItemType {
///     static let cardBackground: ColoredItemType = .init("cardBackground")
/// }
/// ```
///
/// Use the resulting type when constructing a theme's color palette:
///
///     let item = UITheme.ColoredItem(.cardBackground, set: .init(.systemGray6))
public struct ColoredItemType: Hashable, Sendable {
    // MARK: - Properties

    /// The string value that uniquely identifies this color slot.
    public let rawValue: String

    // MARK: - Init

    /// Creates a colored item type with the given identifier.
    ///
    /// - Parameter rawValue: A unique string that identifies this color slot.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}
