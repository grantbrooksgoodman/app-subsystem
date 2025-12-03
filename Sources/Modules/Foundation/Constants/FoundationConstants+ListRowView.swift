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

extension FoundationConstants.CGFloats {
    enum ListRowView {
        static let chevronImageFrameMaxHeight: CGFloat = 14
        static let chevronImageFrameMaxWidth: CGFloat = 14

        static let footerLabelHorizontalPadding: CGFloat = 16
        static let footerLabelSystemFontScale: CGFloat = 13.5
        static let frameMinHeight: CGFloat = UIApplication.isFullyV26Compatible ? 48 : 44

        static let headerLabelHorizontalPadding: CGFloat = 16
        static let headerLabelSystemFontScale: CGFloat = 13.5

        static let imageFrameHeight: CGFloat = 30
        static let imageFrameWidth: CGFloat = 30
        static let imageLeadingPadding: CGFloat = 3

        static let titleLabelLeadingPadding: CGFloat = 5

        static let verticalPadding: CGFloat = UIApplication.isFullyV26Compatible ? 12 : 8
    }
}

// MARK: - Color

extension FoundationConstants.Colors {
    enum ListRowView {
        static let buttonStyleDarkNotPressedBackground: Color = .init(uiColor: .init(hex: 0x2A2A2C))
        static let buttonStyleDarkPressedBackground: Color = .init(uiColor: .init(hex: 0x3A3A3C))

        static let buttonStyleLightNotPressedBackground: Color = .white
        static let buttonStyleLightPressedBackground: Color = .init(uiColor: .init(hex: 0xD1D1D6))

        static let darkBackground: Color = .init(uiColor: .init(hex: 0x2A2A2C))
        static let lightBackground: Color = .white
        static let titleLabelDisabledForeground: Color = .gray
    }
}

// MARK: - String

extension FoundationConstants.Strings {
    enum ListRowView {
        static let chevronImageSystemName = "chevron.forward"
    }
}
