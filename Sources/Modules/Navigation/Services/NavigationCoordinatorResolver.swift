//
//  NavigationCoordinatorResolver.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A singleton that stores and provides access to the app's
/// ``NavigationCoordinator``.
///
/// The resolver acts as the bridge between the coordinator created at
/// app launch and the ``Navigator`` and ``ObservedNavigator``
/// property wrappers that retrieve it later.
///
/// ## Setup
///
/// Store the coordinator once, typically at app launch immediately
/// after creating it:
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
/// - Warning: ``store(_:)`` may only be called once. Calling it a second
///   time results in a fatal error. Similarly, calling ``resolve()`` or
///   using a ``Navigator`` property wrapper before a coordinator has been
///   stored results in a fatal error.
public final class NavigationCoordinatorResolver: @unchecked Sendable {
    // MARK: - Properties

    /// The shared resolver instance.
    public static let shared = NavigationCoordinatorResolver()

    private let _navigationCoordinator = LockIsolated<AnyObject?>(nil)

    // MARK: - Computed Properties

    private var navigationCoordinator: AnyObject? {
        get { _navigationCoordinator.wrappedValue }
        set { _navigationCoordinator.wrappedValue = newValue }
    }

    // MARK: - Init

    private init() {}

    // MARK: - Resolve

    /// Returns the stored coordinator, cast to the requested type.
    ///
    /// - Returns: The stored ``NavigationCoordinator`` instance.
    public func resolve<N: Navigating>() -> NavigationCoordinator<N> {
        guard let navigationCoordinator = navigationCoordinator as? NavigationCoordinator<N> else {
            fatalError(
                navigationCoordinator == nil ?
                    "The NavigationCoordinator instance has not been stored" :
                    "Failed to resolve the NavigationCoordinator instance"
            )
        }

        return navigationCoordinator
    }

    // MARK: - Store

    /// Stores a coordinator for later retrieval.
    ///
    /// Call this method once at app launch. Subsequent calls result
    /// in a fatal error.
    ///
    /// - Parameter navigationCoordinator: The coordinator to store.
    public func store(
        _ navigationCoordinator: NavigationCoordinator<some Navigating>
    ) {
        guard self.navigationCoordinator == nil else {
            fatalError("The NavigationCoordinator instance already exists")
        }

        self.navigationCoordinator = navigationCoordinator
    }

    // MARK: - Update

    /// Replaces the stored coordinator and returns the updated instance.
    ///
    /// - Parameter navigationCoordinator: The coordinator to store.
    ///
    /// - Returns: The newly stored coordinator.
    public func update<N: Navigating>(
        _ navigationCoordinator: NavigationCoordinator<N>
    ) -> NavigationCoordinator<N> {
        self.navigationCoordinator = navigationCoordinator
        guard let updatedNavigationCoordinator = self.navigationCoordinator as? NavigationCoordinator<N> else {
            fatalError("Failed to update the NavigationCoordinator instance")
        }

        return updatedNavigationCoordinator
    }
}
