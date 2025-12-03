//
//  FoundationConstants+RootOverlayView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

// MARK: - CGFloat

extension FoundationConstants.CGFloats {
    enum RootOverlayView {
        static let buildInfoOverlayFrameMaxHeight: CGFloat = 110

        static let fallbackFrameHeight: CGFloat = 100
        static let fallbackFrameOperand: CGFloat = 10
        static let fallbackFrameWidth: CGFloat = 200
        static let fallbackFrameYOriginMaxYOperand: CGFloat = 150 // swiftlint:disable:next identifier_name
        static let fallbackFrameYOriginSafeAreaInsetsOperand: CGFloat = 30
    }
}
