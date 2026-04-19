//
//  UITheme+DataModels.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

public extension UITheme {
    // MARK: - ColoredItem

    /// A pairing of a semantic color slot with the colors used to fill it.
    ///
    /// Each item maps a ``ColoredItemType`` to a ``ColorSet`` that provides
    /// the concrete colors for light and dark appearances:
    ///
    /// ```swift
    /// let accent = UITheme.ColoredItem(.accent, set: .init(.systemBlue))
    /// let background = UITheme.ColoredItem(
    ///     .background,
    ///     set: .init(.white, variant: .black)
    /// )
    /// ```
    ///
    struct ColoredItem: Hashable, Sendable {
        /* MARK: Properties */

        /// The semantic color slot this item fills.
        public let type: ColoredItemType

        /// The colors used for this item in light and dark appearances.
        public let set: ColorSet

        /* MARK: Init */

        /// Creates a colored item that maps a color slot to a set of colors.
        ///
        /// - Parameters:
        ///   - type: The semantic color slot to fill.
        ///   - set: The colors to use for this slot.
        public init(
            _ type: ColoredItemType,
            set: ColorSet
        ) {
            self.type = type
            self.set = set
        }
    }

    // MARK: - ColorSet

    /// A pair of colors representing the light and dark appearance variants
    /// for a single themed color slot.
    ///
    /// Provide only a primary color when the same value should be used in
    /// both appearances. Provide a variant to specify a different color for
    /// dark mode:
    ///
    /// ```swift
    /// // Same color in both appearances.
    /// let accent = UITheme.ColorSet(.systemBlue)
    ///
    /// // White in light mode, black in dark mode.
    /// let background = UITheme.ColorSet(.white, variant: .black)
    /// ```
    ///
    struct ColorSet: Hashable, Sendable {
        /* MARK: Properties */

        /// The color used in light mode, or in both modes when no variant
        /// is provided.
        public let primary: UIColor

        /// The color used in dark mode. When `nil`, the primary color is
        /// used in both appearances.
        public let variant: UIColor?

        /* MARK: Init */

        /// Creates a color set with a primary color and an optional dark
        /// mode variant.
        ///
        /// - Parameters:
        ///   - primary: The color to use in light mode, or in both modes
        ///     if `variant` is `nil`.
        ///   - variant: An optional color to use in dark mode.
        public init(
            _ primary: UIColor,
            variant: UIColor? = nil
        ) {
            self.primary = primary
            self.variant = variant
        }
    }
}
