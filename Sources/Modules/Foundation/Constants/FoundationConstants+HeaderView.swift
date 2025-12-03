//
//  FoundationConstants+HeaderView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

// MARK: - CGFloat

extension FoundationConstants.CGFloats {
    enum HeaderView {
        static let backButtonImageSizeHeight: CGFloat = 20
        static let backButtonImageSizeWidth: CGFloat = 20

        static let dragGestureMinimumDistance: CGFloat = 20
        static let dragGestureValueLeftEdgeThreshold: CGFloat = 20
        static let dragGestureValueRightSwipeThreshold: CGFloat = 60

        static let fullScreenCoverSizeClassFrameMinHeight: CGFloat = 44

        static let horizontalPadding: CGFloat = 16

        static let imageMaxHeight: CGFloat = 30

        // swiftlint:disable:next identifier_name
        static let longCenterItemTextCharacterCountThreshold: CGFloat = 20
        static let longCenterItemTextLineLimit: CGFloat = 2

        static let mainWindowSizeWidthDivisor: CGFloat = 3

        static let separatorMaxHeight: CGFloat = 0.3
        static let sheetSizeClassFrameMinHeight: CGFloat = 54

        static let textMinimumScaleFactor: CGFloat = 0.5
    }
}

// MARK: - Color

extension FoundationConstants.Colors {
    enum HeaderView {
        static let separatorDarkForeground: Color = .init(uiColor: .init(hex: 0x48484A))
        static let separatorLightForeground: Color = .init(uiColor: .init(hex: 0xA3A3A3))
    }
}

// MARK: - String

extension FoundationConstants.Strings {
    enum HeaderView {
        static let backButtonImageSystemName = "chevron.backward"
    }
}
