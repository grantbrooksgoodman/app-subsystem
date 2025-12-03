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

extension FoundationConstants.CGFloats {
    enum FailureView {
        static let exceptionLabelBottomPadding: CGFloat = 10
        static let exceptionLabelFontSize: CGFloat = 22.5
        static let exceptionLabelHorizontalPadding: CGFloat = 20

        static let imageBottomPadding: CGFloat = 10
        static let imageFrameMaxHeight: CGFloat = 120
        static let imageFrameMaxWidth: CGFloat = 120

        static let retryButtonBottomPadding: CGFloat = 5
        static let retryButtonLabelFontSize: CGFloat = 15
    }
}

// MARK: - Color

extension FoundationConstants.Colors {
    enum FailureView {
        static let imageForegroundColor: Color = .red
    }
}

// MARK: - String

extension FoundationConstants.Strings {
    enum FailureView {
        static let imageSystemName = "exclamationmark.octagon.fill"
    }
}
