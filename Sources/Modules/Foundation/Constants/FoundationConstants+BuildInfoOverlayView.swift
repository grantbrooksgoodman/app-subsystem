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

public extension FoundationConstants.CGFloats {
    enum BuildInfoOverlayView {
        public static let buildInfoButtonFrameHeight: CGFloat = 15

        public static let developerModeIndicatorFrameHeight: CGFloat = 8
        public static let developerModeIndicatorFrameWidth: CGFloat = 8
        public static let developerModeIndicatorTrailingPadding: CGFloat = -6

        public static let sendFeedbackButtonFrameHeight: CGFloat = 20
        public static let sendFeedbackButtonLabelFontSize: CGFloat = 12

        public static let statsViewFrameHeight: CGFloat = 15
        public static let translucencyAnimationSpeed: CGFloat = 2
        public static let xOffset: CGFloat = -20
    }
}

// MARK: - Color

public extension FoundationConstants.Colors {
    enum BuildInfoOverlayView {
        public static let buildInfoButtonLabelForeground: Color = .white
        public static let sendFeedbackButtonLabelForeground: Color = .white
        public static let statsLabelForeground: Color = .white
    }
}

// MARK: - String

public extension FoundationConstants.Strings {
    enum BuildInfoOverlayView {
        public static let sendFeedbackButtonLabelFontName = "Arial"
    }
}
