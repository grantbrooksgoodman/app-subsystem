//
//  HeaderView+DataModels.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

public extension HeaderView {
    // MARK: - Attributes

    /// The configuration properties for a ``HeaderView``.
    ///
    /// `Attributes` controls the header's visual appearance, sizing,
    /// and divider visibility.
    struct Attributes {
        /* MARK: Properties */

        let appearance: Appearance
        let restoreOnDisappear: Bool
        let showsDivider: Bool
        let sizeClass: SizeClass

        /* MARK: Init */

        /// Creates header attributes with the given configuration.
        ///
        /// - Parameters:
        ///   - appearance: The background appearance. The default uses
        ///     the navigation bar background color.
        ///   - restoreOnDisappear: Whether to restore the navigation
        ///     bar appearance on disappear. The default is `true`.
        ///   - showsDivider: Whether to show a bottom divider. The
        ///     default is `true`.
        ///   - sizeClass: The sizing behavior. The default is
        ///     ``SizeClass/fullScreenCover``.
        @MainActor
        public init(
            appearance: Appearance = .custom(backgroundColor: .navigationBarBackground),
            restoreOnDisappear: Bool = true,
            showsDivider: Bool = true,
            sizeClass: SizeClass = .fullScreenCover
        ) {
            self.appearance = appearance
            self.restoreOnDisappear = restoreOnDisappear
            self.showsDivider = showsDivider
            self.sizeClass = sizeClass
        }
    }

    // MARK: - Image Attributes

    /// The display properties for an image in a ``HeaderView``.
    struct ImageAttributes {
        /* MARK: Properties */

        let foregroundColor: Color
        let image: Image
        let size: CGSize?
        let weight: Font.Weight

        /* MARK: Init */

        /// Creates image attributes with the given configuration.
        ///
        /// - Parameters:
        ///   - foregroundColor: The foreground color. The default is
        ///     the theme's accent color.
        ///   - image: The image to display.
        ///   - size: An explicit size, or `nil` to scale to fit.
        ///   - weight: The font weight. The default is `.regular`.
        @MainActor
        public init(
            foregroundColor: Color = .accent,
            image: Image,
            size: CGSize? = nil,
            weight: Font.Weight = .regular
        ) {
            self.foregroundColor = foregroundColor
            self.image = image
            self.size = size
            self.weight = weight
        }
    }

    // MARK: - Image Button Attributes

    /// The configuration for an image-based button in a
    /// ``HeaderView``.
    struct ImageButtonAttributes {
        /* MARK: Properties */

        let action: () -> Void
        let image: ImageAttributes
        let isEnabled: Bool

        /* MARK: Init */

        /// Creates image button attributes.
        ///
        /// - Parameters:
        ///   - attributes: The image display properties.
        ///   - isEnabled: Whether the button is enabled. The default
        ///     is `true`.
        ///   - action: The closure to execute on tap.
        public init(
            image attributes: ImageAttributes,
            isEnabled: Bool = true,
            _ action: @escaping () -> Void
        ) {
            image = attributes
            self.isEnabled = isEnabled
            self.action = action
        }
    }

    // MARK: - Text Attributes

    /// The display properties for a text label in a ``HeaderView``.
    struct TextAttributes {
        /* MARK: Properties */

        let font: Font
        let foregroundColor: Color
        let string: String

        /* MARK: Init */

        /// Creates text attributes with the given configuration.
        ///
        /// - Parameters:
        ///   - string: The text to display.
        ///   - font: The font. The default is a 17-point semibold
        ///     system font.
        ///   - foregroundColor: The text color. The default is the
        ///     theme's title text color.
        @MainActor
        public init(
            _ string: String,
            font: Font = .system(size: 17, weight: .semibold),
            foregroundColor: Color = .titleText
        ) {
            self.string = string
            self.font = font
            self.foregroundColor = foregroundColor
        }
    }

    // MARK: - Text Button Attributes

    /// The configuration for a text-based button in a ``HeaderView``.
    struct TextButtonAttributes {
        /* MARK: Properties */

        let action: () -> Void
        let isEnabled: Bool
        let text: TextAttributes

        /* MARK: Init */

        /// Creates text button attributes.
        ///
        /// - Parameters:
        ///   - attributes: The text display properties.
        ///   - isEnabled: Whether the button is enabled. The default
        ///     is `true`.
        ///   - action: The closure to execute on tap.
        public init(
            text attributes: TextAttributes,
            isEnabled: Bool = true,
            _ action: @escaping () -> Void
        ) {
            text = attributes
            self.isEnabled = isEnabled
            self.action = action
        }
    }
}
