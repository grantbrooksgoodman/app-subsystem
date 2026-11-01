//
//  FoundationConstants+Build.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

// MARK: - CGFloat

extension FoundationConstants.CGFloats {
    enum Build {
        static let evaluationPeriodDays: CGFloat = 30
        static let secondsPerDay: CGFloat = 86400
    }
}

// MARK: - String

extension FoundationConstants.Strings {
    enum Build {
        static let buildDateKey = "CFBuildDate"
        static let firstCompileDateKey = "CFFirstCompileDate"
        static let unsetBuildDateValue = "1183100400"
    }
}
