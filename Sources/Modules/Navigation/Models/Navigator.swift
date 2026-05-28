//
//  Navigator.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/// A property wrapper that provides access to the app's
/// ``NavigationCoordinator``.
///
/// Use `@Navigator` in reducers, services, or other non-view code to
/// navigate programmatically:
///
/// ```swift
/// @Navigator var navigator: NavigationCoordinator<AppNavigator>
///
/// func handleLogin() {
///     navigator.navigate(to: .home)
/// }
/// ```
///
/// For SwiftUI views that need to update when the navigation state
/// changes, use ``ObservedNavigator`` instead.
///
/// - Warning: A coordinator must be stored in the
///   ``NavigationCoordinatorResolver`` before this property wrapper is
///   accessed. Accessing it beforehand results in a fatal error.
@propertyWrapper
public struct Navigator<N: Navigating> {
    // MARK: - Properties

    private let value: NavigationCoordinator<N>

    // MARK: - Computed Properties

    public var wrappedValue: NavigationCoordinator<N> {
        NavigationCoordinatorResolver.shared.update(value)
    }

    // MARK: - Init

    public init() {
        value = NavigationCoordinatorResolver.shared.resolve()
    }
}
