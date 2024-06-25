//
//  Navigator.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

@propertyWrapper
public struct Navigator<N: Navigating> {
    // MARK: - Properties

    private let value: NavigationCoordinator<N>

    // MARK: - Computed Properties

    public var wrappedValue: NavigationCoordinator<N> { NavigationCoordinatorResolver.shared.update(value) }

    // MARK: - Init

    public init() {
        value = NavigationCoordinatorResolver.shared.resolve()
    }
}
