//
//  FoundationConstants+FailurePageView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

// MARK: - CGFloat

public extension FoundationConstants.CGFloats {
    enum FailureView {
        public static let buttonLabelFontSize: CGFloat = 14

        public static let exceptionLabelHorizontalPadding: CGFloat = 2
        public static let exceptionLabelVerticalPadding: CGFloat = 5

        public static let imageBottomPadding: CGFloat = 5
        public static let imageFrameMaxHeight: CGFloat = 60
        public static let imageFrameMaxWidth: CGFloat = 60

        public static let reportBugButtonTopPadding: CGFloat = 5
    }
}

// MARK: - Color

public extension FoundationConstants.Colors {
    enum FailureView {
        public static let imageForegroundColor: Color = .red
    }
}

// MARK: - String

public extension FoundationConstants.Strings {
    enum FailureView {
        public static let imageSystemName = "exclamationmark.octagon.fill"
    }
}
