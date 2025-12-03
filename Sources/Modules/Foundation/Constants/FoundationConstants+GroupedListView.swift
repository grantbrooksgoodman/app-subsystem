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

extension FoundationConstants.CGFloats {
    enum GroupedListView {
        static let cornerRadius: CGFloat = UIApplication.isFullyV26Compatible ? 20 : 10

        static let dividerAlternateLeadingPadding: CGFloat = 60
        static let dividerLeadingPadding: CGFloat = 20
        static let dividerTrailingPadding: CGFloat = 20

        static let footerLabelHorizontalPadding: CGFloat = 16
        static let footerLabelSystemFontScale: CGFloat = 13.5

        static let headerLabelHorizontalPadding: CGFloat = 16
        static let headerLabelSystemFontScale: CGFloat = 13.5
    }
}
