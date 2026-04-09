//
//  ObservedNavigator.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

@MainActor
@propertyWrapper
public struct ObservedNavigator<N: Navigating>: DynamicProperty {
    // MARK: - Properties

    @ObservedObject private var value: NavigationCoordinator<N>

    // MARK: - Computed Properties

    public var wrappedValue: NavigationCoordinator<N> { value }

    // MARK: - Init

    public init() {
        value = NavigationCoordinatorResolver.shared.resolve()
    }
}
