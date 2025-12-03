//
//  NavigationBar.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

public enum NavigationBarAppearance: Equatable {
    case custom(NavigationBarConfiguration, scrollEdgeConfig: NavigationBarConfiguration? = nil)
    case `default`(scrollEdgeConfig: NavigationBarConfiguration? = nil)
    case themed(scrollEdgeConfig: NavigationBarConfiguration? = nil, showsDivider: Bool = true)
}

public struct NavigationBarConfiguration: Equatable {
    // MARK: - Properties

    public let backgroundColor: UIColor
    public let barButtonItemColor: UIColor
    public let showsDivider: Bool
    public let titleColor: UIColor

    // MARK: - Computed Properties

    public var uiNavigationBarAppearance: UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()

        switch showsDivider {
        case true:
            appearance.configureWithOpaqueBackground()

        case false:
            appearance.configureWithTransparentBackground()
        }

        appearance.backgroundColor = backgroundColor
        appearance.largeTitleTextAttributes = [
            .foregroundColor: titleColor,
            .strokeColor: barButtonItemColor,
        ]
        appearance.titleTextAttributes = [
            .foregroundColor: titleColor,
            .strokeColor: barButtonItemColor,
        ]

        return appearance
    }

    // MARK: - Init

    public init(
        titleColor: UIColor,
        backgroundColor: UIColor,
        barButtonItemColor: UIColor,
        showsDivider: Bool
    ) {
        self.titleColor = titleColor
        self.backgroundColor = backgroundColor
        self.barButtonItemColor = barButtonItemColor
        self.showsDivider = showsDivider
    }
}

public enum NavigationBar {
    // MARK: - Properties

    public private(set) static var currentAppearance: NavigationBarAppearance?

    // MARK: - Methods

    /// - Note: To be used sparingly and with clear intent; undefined behavior can occur.
    public static func forceRedraw() {
        func toggleNavigationBarIsHidden(_ viewController: UIViewController?) {
            let isNavigationBarHidden = viewController?.navigationController?.isNavigationBarHidden
            let isToolbarHidden = viewController?.navigationController?.isToolbarHidden
            let isNavigationItemTitleViewHidden = viewController?.navigationItem.titleView?.isHidden

            if let isNavigationBarHidden {
                viewController?.navigationController?.isNavigationBarHidden = !isNavigationBarHidden
                viewController?.navigationController?.isNavigationBarHidden = isNavigationBarHidden
            }

            if let isToolbarHidden {
                viewController?.navigationController?.isToolbarHidden = !isToolbarHidden
                viewController?.navigationController?.isToolbarHidden = isToolbarHidden
            }

            if let isNavigationItemTitleViewHidden {
                viewController?.navigationItem.titleView?.isHidden = !isNavigationItemTitleViewHidden
                viewController?.navigationItem.titleView?.isHidden = isNavigationItemTitleViewHidden
            }
        }

        @Dependency(\.uiApplication.presentedViewControllers) var presentedViewControllers: [UIViewController]
        presentedViewControllers.forEach { toggleNavigationBarIsHidden($0) }
    }

    public static func setAppearance(_ appearance: NavigationBarAppearance) {
        switch appearance {
        case let .custom(standardConfig, scrollEdgeConfig: scrollEdgeConfig):
            setAppearance(standardConfig.uiNavigationBarAppearance, scrollEdgeAppearance: scrollEdgeConfig?.uiNavigationBarAppearance)

        case let .default(scrollEdgeConfig: scrollEdgeConfig):
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            setAppearance(appearance, scrollEdgeAppearance: scrollEdgeConfig?.uiNavigationBarAppearance)

        case let .themed(scrollEdgeConfig: scrollEdgeConfig, showsDivider: showsDivider):
            let standardConfig: NavigationBarConfiguration = .init(
                titleColor: .navigationBarTitle,
                backgroundColor: .navigationBarBackground,
                barButtonItemColor: .accent,
                showsDivider: showsDivider
            )
            setAppearance(standardConfig.uiNavigationBarAppearance, scrollEdgeAppearance: scrollEdgeConfig?.uiNavigationBarAppearance)
        }

        currentAppearance = appearance
    }

    private static func setAppearance(_ standardAppearance: UINavigationBarAppearance, scrollEdgeAppearance: UINavigationBarAppearance?) {
        @Dependency(\.uiApplication.presentedViewControllers) var presentedViewControllers: [UIViewController]

        let barButtonItemColor = standardAppearance.titleTextAttributes[.strokeColor] as? UIColor
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = barButtonItemColor

        UINavigationBar.appearance().compactAppearance = standardAppearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = scrollEdgeAppearance ?? standardAppearance

        UINavigationBar.appearance().scrollEdgeAppearance = scrollEdgeAppearance ?? standardAppearance
        UINavigationBar.appearance().standardAppearance = standardAppearance

        // Set properties of root & descendant view instances to ensure global adherence to appearance change.

        for viewController in presentedViewControllers {
            viewController.navigationItem.compactAppearance = standardAppearance
            viewController.navigationItem.compactScrollEdgeAppearance = scrollEdgeAppearance ?? standardAppearance

            viewController.navigationItem.scrollEdgeAppearance = scrollEdgeAppearance ?? standardAppearance
            viewController.navigationItem.standardAppearance = standardAppearance
        }
    }
}
