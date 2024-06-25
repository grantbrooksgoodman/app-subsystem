//
//  NavigationCoordinatorResolver.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public final class NavigationCoordinatorResolver {
    // MARK: - Properties

    public static let shared = NavigationCoordinatorResolver()

    private var navigationCoordinator: AnyObject?

    // MARK: - Init

    private init() {}

    // MARK: - Resolve

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

    public func store<N: Navigating>(_ navigationCoordinator: NavigationCoordinator<N>) {
        guard self.navigationCoordinator == nil else {
            fatalError("The NavigationCoordinator instance already exists")
        }

        self.navigationCoordinator = navigationCoordinator
    }

    // MARK: - Update

    public func update<N: Navigating>(_ navigationCoordinator: NavigationCoordinator<N>) -> NavigationCoordinator<N> {
        self.navigationCoordinator = navigationCoordinator
        guard let updatedNavigationCoordinator = self.navigationCoordinator as? NavigationCoordinator<N> else {
            fatalError("Failed to update the NavigationCoordinator instance")
        }

        return updatedNavigationCoordinator
    }
}
