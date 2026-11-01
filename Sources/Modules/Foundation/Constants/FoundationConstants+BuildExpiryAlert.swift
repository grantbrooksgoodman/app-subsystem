//
//  FoundationConstants+BuildExpiryAlert.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

// MARK: - CGFloat

extension FoundationConstants.CGFloats {
    enum BuildExpiryAlert {
        static let countdownSeconds: CGFloat = 30
        static let exitDelaySeconds: CGFloat = 5
        static let presentationPollMilliseconds: CGFloat = 100
        static let primaryFontSize: CGFloat = 13
        static let secondaryFontSize: CGFloat = 17
        static let translationTimeoutSeconds: CGFloat = 60
        static let wrongCodeRetrySeconds: CGFloat = 2
    }
}
