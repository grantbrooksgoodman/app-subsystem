//
//  FoundationConstants+BuildInfoOverlayView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

// MARK: - CGFloat

extension FoundationConstants.CGFloats {
    enum BuildInfoOverlayView {
        static let buildInfoButtonFrameHeight: CGFloat = 15

        static let developerModeIndicatorFrameHeight: CGFloat = 8
        static let developerModeIndicatorFrameWidth: CGFloat = 8
        static let developerModeIndicatorTrailingPadding: CGFloat = -6

        static let sendFeedbackButtonFrameHeight: CGFloat = 20
        static let sendFeedbackButtonLabelFontSize: CGFloat = 12

        static let statsViewFrameHeight: CGFloat = 15
        static let translucencyAnimationSpeed: CGFloat = 2
        static let xOffset: CGFloat = -20
    }
}

// MARK: - Color

extension FoundationConstants.Colors {
    enum BuildInfoOverlayView {
        static let buildInfoButtonLabelForeground: Color = .white
        static let sendFeedbackButtonLabelForeground: Color = .white
        static let statsLabelForeground: Color = .white
    }
}

// MARK: - String

extension FoundationConstants.Strings {
    enum BuildInfoOverlayView {
        static let sendFeedbackButtonLabelFontName = "Arial"
    }
}
