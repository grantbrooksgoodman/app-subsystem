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

extension FoundationConstants.CGFloats {
    enum ForcedUpdateModalPageView {
        static let appIconImageBottomPadding: CGFloat = 10
        static let appIconImageCornerRadius: CGFloat = 24
        static let appIconImageMaxHeight: CGFloat = 120
        static let appIconImageMaxWidth: CGFloat = 120
        static let appIconImageOverlaySymbolFrameMaxHeight: CGFloat = 40
        static let appIconImageOverlaySymbolFrameMaxWidth: CGFloat = 40
        static let appIconImageOverlaySymbolXOffset: CGFloat = 8
        static let appIconImageOverlaySymbolYOffset: CGFloat = 10

        static let subtitleLabelTextBottomPadding: CGFloat = 10
        static let subtitleLabelTextHorizontalPadding: CGFloat = 20
        static let subtitleLabelTextSystemFontScale: CGFloat = 15

        static let titleLabelTextBottomPadding: CGFloat = 5
        static let titleLabelTextHorizontalPadding: CGFloat = 5

        static let transitionAnimationDuration: CGFloat = 0.25
    }
}

// MARK: - Color

extension FoundationConstants.Colors {
    enum ForcedUpdateModalPageView {
        static let appIconImageOverlayForeground: Color = .white
        static let appIconImageOverlaySecondaryForeground: Color = .yellow
        static let versionLabelTextForeground: Color = .init(uiColor: .systemGray2)
    }
}

// MARK: - String

extension FoundationConstants.Strings {
    enum ForcedUpdateModalPageView {
        static let appIconImageOverlaySymbolName = "exclamationmark.triangle.fill"
    }
}
