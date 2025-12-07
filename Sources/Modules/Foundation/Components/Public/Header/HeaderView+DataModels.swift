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

    struct Attributes {
        /* MARK: Properties */

        let appearance: Appearance
        let showsDivider: Bool
        let sizeClass: SizeClass

        /* MARK: Init */

        public init(
            appearance: Appearance = .custom(backgroundColor: .navigationBarBackground),
            showsDivider: Bool = true,
            sizeClass: SizeClass = .fullScreenCover
        ) {
            self.appearance = appearance
            self.showsDivider = showsDivider
            self.sizeClass = sizeClass
        }
    }

    // MARK: - Image Attributes

    struct ImageAttributes {
        /* MARK: Properties */

        let foregroundColor: Color
        let image: Image
        let size: CGSize?
        let weight: Font.Weight

        /* MARK: Init */

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

    struct ImageButtonAttributes {
        /* MARK: Properties */

        let action: () -> Void
        let image: ImageAttributes
        let isEnabled: Bool

        /* MARK: Init */

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

    struct TextAttributes {
        /* MARK: Properties */

        let font: Font
        let foregroundColor: Color
        let string: String

        /* MARK: Init */

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

    struct TextButtonAttributes {
        /* MARK: Properties */

        let action: () -> Void
        let isEnabled: Bool
        let text: TextAttributes

        /* MARK: Init */

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
