//
//  FoundationConstants+DevModeMenuView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

// MARK: - CGFloat

extension FoundationConstants.CGFloats {
    enum DevModeMenuView {
        static let groupedListViewHorizontalPadding: CGFloat = 20
        static let groupedListViewSpacing: CGFloat = 20
        static let groupedListViewVerticalPadding: CGFloat = 20
    }
}

// MARK: - Color

extension FoundationConstants.Colors {
    enum DevModeMenuView {
        static let destructiveRowForeground: Color = .red
    }
}

// MARK: - String

extension FoundationConstants.Strings {
    enum DevModeMenuView {
        static let appDomainHeaderText = "App Domain"
        static let disableDeveloperModeRowText = "Disable Developer Mode"
        static let headerTitleText = "Developer Mode"
        static let subsystemDomainHeaderText = "Subsystem Domain"
    }
}
