//
//  NavigatingProtocol.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/// A type that defines how routes are applied to navigation state.
///
/// Conform to `Navigating` to describe the navigation behavior of your
/// app. The conforming type declares the set of routes a user can
/// take and how each route modifies the navigation state:
///
/// ```swift
/// struct AppNavigator: Navigating {
///    enum Route {
///        case home
///        case profile(userID: String)
///        case settings
///        case dismiss
///    }
///
///    func navigate(to route: Route, on state: inout AppNavigationState) {
///        switch route {
///        case .home:
///            state.stack.removeAll()
///        case .profile(let userID):
///            state.stack.append(.profile(userID: userID))
///        case .settings:
///            state.sheet = .settings
///        case .dismiss:
///            state.sheet = nil
///        }
///    }
/// }
/// ```
///
/// Pass the conforming instance to a ``NavigationCoordinator`` at
/// initialization to begin handling navigation.
///
/// - SeeAlso: ``NavigatorState``, ``NavigationCoordinator``
public protocol Navigating {
    // MARK: - Associated Types

    /// The type that enumerates the navigable destinations.
    associatedtype Route

    /// The type that holds the current navigation state.
    associatedtype State: NavigatorState

    // MARK: - Methods

    /// Applies the given route to the navigation state.
    ///
    /// Modify `state` to reflect the desired navigation change. The
    /// ``NavigationCoordinator`` publishes the updated state, and SwiftUI
    /// responds to the change automatically.
    ///
    /// - Parameters:
    ///   - route: The destination to navigate to.
    ///   - state: The current navigation state, passed as `inout` so that
    ///     it can be modified in place.
    func navigate(to route: Route, on state: inout State)
}
