//
//  FoundationConstants+GroupedListView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

// MARK: - CGFloat

public extension FoundationConstants.CGFloats {
    enum GroupedListView {
        public static let cornerRadius: CGFloat = UIApplication.isFullyV26Compatible ? 20 : 10

        public static let dividerAlternateLeadingPadding: CGFloat = 60
        public static let dividerLeadingPadding: CGFloat = 20
        public static let dividerTrailingPadding: CGFloat = 20

        public static let footerLabelHorizontalPadding: CGFloat = 16
        public static let footerLabelSystemFontScale: CGFloat = 13.5

        public static let headerLabelHorizontalPadding: CGFloat = 16
        public static let headerLabelSystemFontScale: CGFloat = 13.5
    }
}
