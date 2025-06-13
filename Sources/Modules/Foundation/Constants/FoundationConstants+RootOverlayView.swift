//
//  FoundationConstants+RootOverlayView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

// MARK: - CGFloat

public extension FoundationConstants.CGFloats {
    enum RootOverlayView {
        public static let buildInfoOverlayFrameMaxHeight: CGFloat = 110

        public static let fallbackFrameHeight: CGFloat = 100
        public static let fallbackFrameOperand: CGFloat = 10
        public static let fallbackFrameWidth: CGFloat = 200
        public static let fallbackFrameYOriginMaxYOperand: CGFloat = 150 // swiftlint:disable:next identifier_name
        public static let fallbackFrameYOriginSafeAreaInsetsOperand: CGFloat = 30
    }
}
