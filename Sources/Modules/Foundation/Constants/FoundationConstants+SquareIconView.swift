//
//  FoundationConstants+SquareIconView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

// MARK: - CGFloat

extension FoundationConstants.CGFloats {
    enum SquareIconView {
        static let cornerRadius: CGFloat = 30

        static let shadowColorOpacity: CGFloat = 0.2
        static let shadowRadius: CGFloat = 10
        static let shadowYOffset: CGFloat = 5
    }
}

// MARK: - Color

extension FoundationConstants.Colors {
    enum SquareIconView {
        static let shadow: Color = .black
    }
}
