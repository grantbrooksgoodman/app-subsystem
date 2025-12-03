//
//  FoundationConstants+ToastView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

// MARK: - CGFloat

extension FoundationConstants.CGFloats {
    enum ToastView {
        static let bannerCornerRadius: CGFloat = 8 // swiftlint:disable:next identifier_name
        static let bannerDismissButtonForegroundColorOpacity: CGFloat = 0.7
        static let bannerHorizontalPadding: CGFloat = 16

        static let bannerMessageLabelForegroundColorOpacity: CGFloat = 0.6
        static let bannerMessageLabelFontSize: CGFloat = 12

        static let bannerOverlayFrameWidth: CGFloat = 6

        static let bannerShadowColorOpacity: CGFloat = 0.25
        static let bannerShadowRadius: CGFloat = 4
        static let bannerShadowX: CGFloat = 0
        static let bannerShadowY: CGFloat = 1

        static let bannerSpacerMinLength: CGFloat = 10

        static let bannerTitleLabelFontSize: CGFloat = 14
        static let bannerTitleLabelForegroundColorOpacity: CGFloat = 0.6

        static let bottomAppearanceEdgePadding: CGFloat = 30
        static let bottomAppearanceEdgeYOffset: CGFloat = -20

        static let capsuleImageFrameMaxHeight: CGFloat = 20
        static let capsuleImageFrameMaxWidth: CGFloat = 20

        static let capsuleMessageLabelFontSize: CGFloat = 12
        static let capsuleTitleLabelFontSize: CGFloat = 14

        static let capsuleMessageLabelHorizontalPadding: CGFloat = 5
        static let capsuleMessageLabelVerticalPadding: CGFloat = 5

        static let capsuleOverlayStrokeColorOpacity: CGFloat = 0.2
        static let capsuleOverlayStrokeLineWidth: CGFloat = 1

        static let capsulePrimaryHorizontalPadding: CGFloat = 20
        static let capsuleSecondaryHorizontalPadding: CGFloat = 16
        static let capsuleVerticalPadding: CGFloat = 10

        static let capsuleShadowColorOpacity: CGFloat = 0.1
        static let capsuleShadowRadius: CGFloat = 5
        static let capsuleShadowX: CGFloat = 0
        static let capsuleShadowY: CGFloat = 6

        static let iOS27SpringAnimationSpeed: CGFloat = 1.5

        static let topAppearanceEdgePadding: CGFloat = 30
        static let topAppearanceEdgeYOffset: CGFloat = 20
    }
}

// MARK: - Color

extension FoundationConstants.Colors {
    enum ToastView {
        static let bannerShadowColor: Color = .black
        static let capsuleShadowColor: Color = .black

        static let capsuleMessageLabelForeground: Color = .gray
        static let capsuleOverlayStroke: Color = .gray

        static let defaultErrorColor: Color = .red
        static let defaultInfoColor: Color = .init(uiColor: .systemBlue)
        static let defaultSuccessColor: Color = .green
        static let defaultWarningColor: Color = .orange
    }
}

// MARK: - String

extension FoundationConstants.Strings {
    enum ToastView {
        static let bannerDismissButtonImageSystemName = "xmark"

        static let bannerErrorIconImageSystemName = "xmark.circle.fill"
        static let bannerInfoIconImageSystemName = "info.circle.fill"
        static let bannerSuccessIconImageSystemName = "checkmark.circle.fill"
        static let bannerWarningIconImageSystemName = "exclamationmark.triangle.fill"

        static let capsuleErrorIconImageSystemName = "xmark"
        static let capsuleInfoIconImageSystemName = "info"
        static let capsuleSuccessIconImageSystemName = "checkmark"
        static let capsuleWarningIconImageSystemName = "exclamationmark.triangle.fill"
    }
}
