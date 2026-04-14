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

    struct ColoredItem: Equatable, Sendable {
        /* MARK: Properties */

        public let type: ColoredItemType
        public let set: ColorSet

        /* MARK: Init */

        public init(
            _ type: ColoredItemType,
            set: ColorSet
        ) {
            self.type = type
            self.set = set
        }
    }

    // MARK: - ColorSet

    struct ColorSet: Equatable, Sendable {
        /* MARK: Properties */

        public let primary: UIColor
        public let variant: UIColor?

        /* MARK: Init */

        public init(
            _ primary: UIColor,
            variant: UIColor? = nil
        ) {
            self.primary = primary
            self.variant = variant
        }
    }
}
