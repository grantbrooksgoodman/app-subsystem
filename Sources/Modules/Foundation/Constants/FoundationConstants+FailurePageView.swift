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
        public static let exceptionLabelBottomPadding: CGFloat = 10
        public static let exceptionLabelFontSize: CGFloat = 22.5
        public static let exceptionLabelHorizontalPadding: CGFloat = 20

        public static let imageBottomPadding: CGFloat = 10
        public static let imageFrameMaxHeight: CGFloat = 120
        public static let imageFrameMaxWidth: CGFloat = 120

        public static let retryButtonBottomPadding: CGFloat = 5
        public static let retryButtonLabelFontSize: CGFloat = 15
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
