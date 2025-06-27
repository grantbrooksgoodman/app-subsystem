//
//  FoundationConstants+ForcedUpdateModalPageView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

// MARK: - CGFloat

public extension FoundationConstants.CGFloats {
    enum ForcedUpdateModalPageView {
        public static let appIconImageBottomPadding: CGFloat = 10
        public static let appIconImageCornerRadius: CGFloat = 24
        public static let appIconImageMaxHeight: CGFloat = 120
        public static let appIconImageMaxWidth: CGFloat = 120
        public static let appIconImageOverlaySymbolFrameMaxHeight: CGFloat = 40
        public static let appIconImageOverlaySymbolFrameMaxWidth: CGFloat = 40
        public static let appIconImageOverlaySymbolXOffset: CGFloat = 8
        public static let appIconImageOverlaySymbolYOffset: CGFloat = 10

        public static let subtitleLabelTextBottomPadding: CGFloat = 10
        public static let subtitleLabelTextHorizontalPadding: CGFloat = 20
        public static let subtitleLabelTextSystemFontScale: CGFloat = 15

        public static let titleLabelTextBottomPadding: CGFloat = 5
        public static let titleLabelTextHorizontalPadding: CGFloat = 5

        public static let transitionAnimationDuration: CGFloat = 0.3
    }
}

// MARK: - Color

public extension FoundationConstants.Colors {
    enum ForcedUpdateModalPageView {
        public static let appIconImageOverlayForeground: Color = .white
        public static let appIconImageOverlaySecondaryForeground: Color = .yellow
        public static let installButtonTextForeground: Color = .white
        public static let versionLabelTextForeground: Color = .init(uiColor: .systemGray2)
    }
}

// MARK: - String

public extension FoundationConstants.Strings {
    enum ForcedUpdateModalPageView {
        public static let appIconImageOverlaySymbolName = "exclamationmark.triangle.fill"
    }
}
