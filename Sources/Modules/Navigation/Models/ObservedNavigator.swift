//
//  ObservedNavigator.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/// A property wrapper that provides an observable reference to the
/// app's ``NavigationCoordinator`` for use in SwiftUI views.
///
/// Use `@ObservedNavigator` when a view's body depends on the navigation
/// state. The view automatically updates when the coordinator's published
/// state changes:
///
/// ```swift
/// struct RootView: View {
///     @ObservedNavigator var navigator: NavigationCoordinator<AppNavigator>
///
///     var body: some View {
///         NavigationStack(path: navigator.navigable(\.stack, route: { _ in .pop })) {
///             // ...
///         }
///         .sheet(item: navigator.navigable(\.sheet, route: { _ in .dismiss })) { path in
///             // ...
///         }
///     }
/// }
/// ```
///
/// For non-view code that only needs to trigger navigation without
/// observing state changes, use ``Navigator`` instead.
///
/// - Warning: A coordinator must be stored in the
///   ``NavigationCoordinatorResolver`` before this property wrapper is
///   accessed. Accessing it beforehand results in a fatal error.
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
