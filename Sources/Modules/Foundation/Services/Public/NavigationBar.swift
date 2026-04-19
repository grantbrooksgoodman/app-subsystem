//
//  NavigationBar.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

/// A description of the visual appearance to apply to navigation
/// bars.
///
/// Use one of the three cases to configure navigation bars globally
/// through ``NavigationBar/setAppearance(_:)``:
///
/// - ``custom(_:scrollEdgeConfig:)`` – Fully custom colors and
///   divider settings.
/// - ``default(scrollEdgeConfig:)`` – The system default appearance.
/// - ``themed(scrollEdgeConfig:showsDivider:)`` – An appearance
///   derived from the active ``UITheme``.
///
/// Each case optionally accepts a separate
/// ``NavigationBarConfiguration`` for the scroll-edge state.
///
/// - SeeAlso: ``NavigationBar``, ``NavigationBarConfiguration``
public enum NavigationBarAppearance: Equatable, Sendable {
    /// A fully custom appearance.
    ///
    /// - Parameters:
    ///   - configuration: The standard navigation bar configuration.
    ///   - scrollEdgeConfig: An optional configuration applied when
    ///     content is scrolled to the top.
    case custom(
        NavigationBarConfiguration,
        scrollEdgeConfig: NavigationBarConfiguration? = nil
    )

    /// The system default appearance.
    ///
    /// - Parameter scrollEdgeConfig: An optional configuration
    ///   applied when content is scrolled to the top.
    case `default`(
        scrollEdgeConfig: NavigationBarConfiguration? = nil
    )

    /// An appearance derived from the active UI theme.
    ///
    /// Colors are resolved from the current theme's navigation bar
    /// palette.
    ///
    /// - Parameters:
    ///   - scrollEdgeConfig: An optional configuration applied when
    ///     content is scrolled to the top.
    ///   - showsDivider: Whether the navigation bar displays a
    ///     bottom divider. The default is `true`.
    case themed(
        scrollEdgeConfig: NavigationBarConfiguration? = nil,
        showsDivider: Bool = true
    )
}

/// A set of colors and display options that define the appearance of
/// a navigation bar.
///
/// Create a configuration and pass it to
/// ``NavigationBarAppearance/custom(_:scrollEdgeConfig:)`` or use
/// it as a scroll-edge override on any appearance case:
///
/// ```swift
/// let configuration = NavigationBarConfiguration(
///     titleColor: .white,
///     backgroundColor: .systemBlue,
///     barButtonItemColor: .white,
///     showsDivider: false
/// )
///
/// NavigationBar.setAppearance(.custom(configuration))
/// ```
///
/// - SeeAlso: ``NavigationBarAppearance``, ``NavigationBar``
public struct NavigationBarConfiguration: Equatable, Sendable {
    // MARK: - Properties

    let backgroundColor: UIColor
    let barButtonItemColor: UIColor
    let showsDivider: Bool
    let titleColor: UIColor

    // MARK: - Computed Properties

    @MainActor
    var uiNavigationBarAppearance: UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()

        switch showsDivider {
        case true: appearance.configureWithOpaqueBackground()
        case false: appearance.configureWithTransparentBackground()
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

    /// Creates a navigation bar configuration.
    ///
    /// - Parameters:
    ///   - titleColor: The color of the title text.
    ///   - backgroundColor: The background color.
    ///   - barButtonItemColor: The tint color for bar button items.
    ///   - showsDivider: Whether to display a bottom divider.
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

/// A service for managing the global appearance and layout of
/// navigation bars.
///
/// Use `NavigationBar` to apply a consistent appearance to all
/// navigation bars in the app:
///
/// ```swift
/// NavigationBar.setAppearance(.themed())
/// ```
///
/// The service also provides the current navigation bar
/// ``height`` and the ability to ``forceRedraw()`` when
/// needed.
///
/// - Note: All members of `NavigationBar` are isolated to the main
///   actor.
///
/// - SeeAlso: ``NavigationBarAppearance``,
///   ``NavigationBarConfiguration``
@MainActor
public enum NavigationBar {
    // MARK: - Properties

    /// The appearance most recently applied through
    /// ``setAppearance(_:)``, or `nil` if no appearance has been
    /// set.
    public private(set) static var currentAppearance: NavigationBarAppearance?

    // MARK: - Computed Properties

    /// The height of the navigation bar in the topmost navigation
    /// controller.
    ///
    /// Returns the smallest current navigation bar height across all
    /// presented navigation controllers, or the system default if no
    /// navigation controller is present.
    public static var height: CGFloat {
        typealias Floats = FoundationConstants.CGFloats.NavigationBar
        @Dependency(\.uiApplication.presentedViewControllers) var viewControllers: [UIViewController]

        let minimumCurrentHeight = viewControllers
            .compactMap { $0 as? UINavigationController }
            .map(\.navigationBar.frame.height)
            .sorted()
            .first ?? Floats.defaultHeight

        guard minimumCurrentHeight > 0 else { return Floats.defaultHeight }
        return min(
            minimumCurrentHeight,
            Floats.defaultHeight
        )
    }

    // MARK: - Methods

    /// Forces all visible navigation bars to update.
    ///
    /// This method toggles the hidden state of each navigation bar,
    /// toolbar, and title view to trigger a layout pass.
    ///
    /// - Warning: Use this method sparingly and with clear intent;
    ///   undefined behavior can occur.
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

    /// Applies the given appearance to all navigation bars in the
    /// app.
    ///
    /// The appearance is set globally through
    /// `UINavigationBar.appearance()` and also applied directly to
    /// every currently presented navigation controller to ensure
    /// immediate effect.
    ///
    /// - Parameter appearance: The appearance to apply.
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
