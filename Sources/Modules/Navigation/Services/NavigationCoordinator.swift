//
//  NavigationCoordinator.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/// An object that owns the navigation state and dispatches route changes.
///
/// `NavigationCoordinator` is the central object in the navigation system.
/// It holds the current ``NavigatorState``, publishes changes for SwiftUI,
/// and delegates route handling to a ``Navigating`` instance.
///
/// ## Setup
///
/// Create a coordinator with an initial state and a navigator, then store
/// it in the ``NavigationCoordinatorResolver`` so that property wrappers
/// can find it:
///
/// ```swift
/// let coordinator = NavigationCoordinator(
///    AppNavigationState(),
///    navigating: AppNavigator()
/// )
///
/// NavigationCoordinatorResolver.shared.store(coordinator)
/// ```
///
/// ## Navigating
///
/// Call ``navigate(to:)`` to trigger a route. The coordinator forwards the
/// route to the ``Navigating`` instance, which modifies the state:
///
///     coordinator.navigate(to: .profile(userID: "42"))
///
/// ## SwiftUI Bindings
///
/// Use ``navigable(_:route:)`` to create a two-way binding suitable for
/// SwiftUI presentation modifiers. The getter reads the current state and
/// the setter dispatches a route:
///
///     .sheet(item: coordinator.navigable(\.sheet, route: { .dismiss })) { path in
///         // ...
///     }
@MainActor
public final class NavigationCoordinator<N: Navigating>: ObservableObject {
    // MARK: - Properties

    /// The current navigation state.
    ///
    /// This property is published so that SwiftUI views observing the
    /// coordinator update automatically when the state changes.
    @Published public private(set) var state: N.State

    private let navigating: N

    // MARK: - Init

    /// Creates a coordinator with the given initial state and navigator.
    ///
    /// - Parameters:
    ///   - state: The initial navigation state.
    ///   - navigating: The object that handles route-to-state mapping.
    public init(_ state: N.State, navigating: N) {
        self.state = state
        self.navigating = navigating
    }

    // MARK: - Navigable

    /// Returns a binding that reads from the navigation state and writes
    /// through a route.
    ///
    /// Use this method to bridge the coordinator's state to SwiftUI
    /// presentation modifiers that require a `Binding`:
    ///
    ///     .sheet(item: coordinator.navigable(\.sheet, route: { .dismiss })) { ... }
    ///
    /// - Parameters:
    ///   - keyPath: A key path to the state property to read.
    ///   - transform: A closure that converts the new value into a route
    ///     to dispatch.
    ///
    /// - Returns: A binding backed by the navigation state.
    public func navigable<Value>(
        _ keyPath: KeyPath<N.State, Value>,
        route transform: @escaping (Value) -> N.Route
    ) -> Binding<Value> {
        Binding<Value>(
            get: { self.state[keyPath: keyPath] },
            set: { self.navigate(to: transform($0)) }
        )
    }

    // MARK: - Navigate To

    /// Navigates to the given route.
    ///
    /// The route is forwarded to the ``Navigating`` instance, which
    /// modifies the navigation state. SwiftUI views observing this
    /// coordinator update automatically.
    ///
    /// - Parameter route: The destination to navigate to.
    public func navigate(to route: N.Route) {
        navigating.navigate(to: route, on: &state)
    }
}
