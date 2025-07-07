//
//  FoundationConstants+ListRowView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

// MARK: - CGFloat

public extension FoundationConstants.CGFloats {
    enum ListRowView {
        public static let chevronImageFrameMaxHeight: CGFloat = 14
        public static let chevronImageFrameMaxWidth: CGFloat = 14

        public static let footerLabelHorizontalPadding: CGFloat = 16
        public static let footerLabelSystemFontScale: CGFloat = 13.5
        public static let frameMinHeight: CGFloat = UIApplication.isFullyV26Compatible ? 48 : 44

        public static let headerLabelHorizontalPadding: CGFloat = 16
        public static let headerLabelSystemFontScale: CGFloat = 13.5

        public static let imageFrameHeight: CGFloat = 30
        public static let imageFrameWidth: CGFloat = 30
        public static let imageLeadingPadding: CGFloat = 3

        public static let titleLabelLeadingPadding: CGFloat = 5

        public static let verticalPadding: CGFloat = UIApplication.isFullyV26Compatible ? 12 : 8
    }
}

// MARK: - Color

public extension FoundationConstants.Colors {
    enum ListRowView {
        public static let buttonStyleDarkNotPressedBackground: Color = .init(uiColor: .init(hex: 0x2A2A2C))
        public static let buttonStyleDarkPressedBackground: Color = .init(uiColor: .init(hex: 0x3A3A3C))

        public static let buttonStyleLightNotPressedBackground: Color = .white
        public static let buttonStyleLightPressedBackground: Color = .init(uiColor: .init(hex: 0xD1D1D6))

        public static let darkBackground: Color = .init(uiColor: .init(hex: 0x2A2A2C))
        public static let lightBackground: Color = .white
        public static let titleLabelDisabledForeground: Color = .gray
    }
}

// MARK: - String

public extension FoundationConstants.Strings {
    enum ListRowView {
        public static let chevronImageSystemName = "chevron.forward"
    }
}
