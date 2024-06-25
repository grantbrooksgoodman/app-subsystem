//
//  EnvironmentValues+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

public extension EnvironmentValues {
    // MARK: - Types

    private struct MainWindowSizeKey: EnvironmentKey {
        public static let defaultValue: CGSize = .zero
    }

    // MARK: - Properties

    var mainWindowSize: CGSize {
        get { self[MainWindowSizeKey.self] }
        set { self[MainWindowSizeKey.self] = newValue }
    }
}
