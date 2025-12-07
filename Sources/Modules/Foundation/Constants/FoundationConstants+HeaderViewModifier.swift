//
//  FoundationConstants+HeaderViewModifier.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

// MARK: - CGFloat

extension FoundationConstants.CGFloats {
    enum HeaderViewModifier {
        static let imageMaxWidthDivisor: CGFloat = 3
        static let navigationBarHeightIncrement: CGFloat = 20
        static let toolbarButtonHeight: CGFloat = 30
        static let toolbarButtonWidth: CGFloat = 30
        static let toolbarButtonLabelHorizontalPadding: CGFloat = 8
        static let toolbarButtonLabelMinimumScaleFactor: CGFloat = 0.5
    }
}

// MARK: - String

extension FoundationConstants.Strings {
    enum HeaderViewModifier {
        static let cancelToolbarButtonImageSystemName = "xmark"
        static let doneToolbarButtonImageSystemName = "checkmark"
    }
}
