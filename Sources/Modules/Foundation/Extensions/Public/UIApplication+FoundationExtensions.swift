//
//  UIApplication+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

public extension UIApplication {
    // MARK: - Properties

    /// A Boolean value indicating whether the device is running
    /// iOS 26 or later.
    static let iOS26IsAvailable: Bool = {
        if #available(iOS 26, *) { return true }
        return false
    }()

    /// A Boolean value indicating whether the device is running
    /// iOS 27 or later.
    static let iOS27IsAvailable: Bool = {
        if #available(iOS 27, *) { return true }
        return false
    }()

    /// A Boolean value indicating whether the app is running on
    /// iOS 26 or later, was compiled for it, and does not require
    /// pre-iOS 26 design compatibility.
    static let isFullyV26Compatible: Bool = !UIApplication.bundleRequiresPreV26Design &&
        UIApplication.iOS26IsAvailable &&
        UIApplication.isCompiledForV26OrLater

    /// A Boolean value indicating whether glass tinting is enabled
    /// and the app is fully iOS 26 compatible.
    static var isGlassTintingEnabled: Bool {
        @Persistent(.isGlassTintingEnabled) var isGlassTintingEnabled: Bool?
        guard UIApplication.isFullyV26Compatible,
              isGlassTintingEnabled == true else { return false }
        return true
    }

    /// The current first responder view, or `nil`.
    var firstResponder: UIView? {
        firstResponder()
    }

    /// The user interface style override on the main window, or
    /// `nil`.
    var interfaceStyle: UIUserInterfaceStyle? {
        mainWindow?.overrideUserInterfaceStyle
    }

    /// A Boolean value indicating whether a `UIAlertController` is
    /// currently presented.
    var isPresentingAlertController: Bool {
        presentedViewControllers.contains(where: { $0 is UIAlertController })
    }

    /// A Boolean value indicating whether a sheet is currently
    /// presented.
    var isPresentingSheet: Bool {
        presentedViewControllers.contains(where: { $0.activePresentationController is UISheetPresentationController })
    }

    /// The topmost visible view controller in the main window's
    /// hierarchy.
    var keyViewController: UIViewController? {
        keyViewController(mainWindow?.rootViewController)
    }

    /// The screen associated with the main window.
    var mainScreen: UIScreen {
        mainWindow?.screen ?? .main
    }

    /// The app's key window, or `nil`.
    var mainWindow: UIWindow? {
        windows.first(where: \.isKeyWindow)
    }

    /// Recursively resolves all view controllers (including parents & children) associated with all windows in all window scenes.
    var presentedViewControllers: [UIViewController] {
        presentedViewControllers()
    }

    /// Recursively resolves all views (including superviews & subviews) associated with all windows in all window scenes.
    var presentedViews: [UIView] {
        presentedViews()
    }

    /// A screenshot of the current screen contents.
    var snapshot: UIImage? {
        #if targetEnvironment(simulator)
        let snapshotView = mainScreen.snapshotView(afterScreenUpdates: true)
        snapshotView.bounds = .init(origin: .zero, size: mainScreen.bounds.size)

        let renderer = UIGraphicsImageRenderer(size: mainScreen.bounds.size)
        return renderer.image { _ in
            snapshotView.drawHierarchy(in: mainScreen.bounds, afterScreenUpdates: true)
        }
        #else
        guard let mainWindow else { return nil }
        var image: UIImage?

        UIGraphicsBeginImageContextWithOptions(mainWindow.layer.frame.size, false, mainWindow.screen.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        mainWindow.layer.render(in: context)

        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
        #endif
    }

    /// All windows across all connected scenes.
    var windows: [UIWindow] {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
    }

    private static var bundleRequiresPreV26Design: Bool {
        @Dependency(\.mainBundle) var mainBundle: Bundle

        if let _bundleRequiresPreV26Design {
            return _bundleRequiresPreV26Design
        }

        let designRequiresCompatibility = mainBundle.object(
            forInfoDictionaryKey: "UIDesignRequiresCompatibility"
        ) as? Bool

        _bundleRequiresPreV26Design = designRequiresCompatibility
        return designRequiresCompatibility ?? false
    }

    private static var isCompiledForV26OrLater: Bool {
        #if compiler(>=6.2)
        return true
        #else
        return false
        #endif
    }

    private static var _bundleRequiresPreV26Design: Bool?

    // MARK: - Methods

    /// Dismisses all currently presented alert controllers.
    func dismissAlertControllers(animated: Bool = true) {
        guard isPresentingAlertController else { return }
        presentedViewControllers
            .compactMap { $0 as? UIAlertController }
            .forEach { $0.dismiss(animated: animated) }
    }

    /// Dismisses all currently presented sheets.
    func dismissSheets(animated: Bool = true) {
        guard isPresentingSheet else { return }
        presentedViewControllers
            .filter { $0.activePresentationController is UISheetPresentationController }
            .forEach { $0.dismiss(animated: animated) }
    }

    /// Returns the first responder within the given view, or across
    /// all presented views when `nil`.
    func firstResponder(in view: UIView? = nil) -> UIView? {
        guard let view else { return presentedViews.first(where: { $0.isFirstResponder }) }
        guard !view.isFirstResponder else { return view }
        return view.traversedSubviews.first(where: { $0.isFirstResponder })
    }

    /// Overrides the user interface style on all windows and view
    /// controllers.
    func overrideUserInterfaceStyle(_ style: UIUserInterfaceStyle) {
        presentedViewControllers.forEach { $0.overrideUserInterfaceStyle = style }
        windows.forEach { $0.overrideUserInterfaceStyle = style }
    }

    /// Recursively resolves all view controllers (including parents & children) associated with either the key window, or all windows in all window scenes.
    func presentedViewControllers(_ mainWindowOnly: Bool = false) -> [UIViewController] {
        let windows = mainWindowOnly ? (mainWindow.map { [$0] } ?? []) : windows
        var viewControllers = [UIViewController?]()

        for window in windows {
            guard let rootViewController = window.rootViewController else { continue }

            viewControllers += [rootViewController]
                + rootViewController.descendants() as [UIViewController]
                + (
                    rootViewController.traversedPresentedViewControllers + rootViewController.traversedPresentingViewControllers
                )
                .flatMap { [$0] + $0.ancestors() + $0.descendants() }
        }

        viewControllers.forEach { viewControllers.append(keyViewController($0)) }
        return viewControllers.compactMap(\.self).unique
    }

    /// Recursively resolves all views (including superviews & subviews) associated with either the key window, or all windows in all window scenes.
    func presentedViews(_ mainWindowOnly: Bool = false) -> [UIView] {
        let windowAttachedViews = (mainWindowOnly ? (mainWindow.map { [$0] } ?? []) : windows)
            .flatMap { [$0] + $0.traversedSubviews + $0.traversedSuperviews }
        let viewControllerViews = presentedViewControllers(mainWindowOnly)
            .compactMap(\.view)
        let viewControllerSubtrees = viewControllerViews
            .flatMap { [$0] + $0.traversedSubviews + $0.traversedSuperviews }

        return (windowAttachedViews + viewControllerViews + viewControllerSubtrees).unique
    }

    /// Resigns all first responders within the given view, or
    /// across all presented views when `nil`.
    func resignFirstResponders(in view: UIView? = nil) {
        guard let view else {
            return presentedViews
                .filter(\.isFirstResponder)
                .forEach { $0.resignFirstResponder() }
        }

        guard let firstResponder = firstResponder(in: view) else { return }
        firstResponder.resignFirstResponder()
    }

    private func keyViewController(_ baseVC: UIViewController?) -> UIViewController? {
        if let navigationController = baseVC as? UINavigationController {
            return keyViewController(navigationController.visibleViewController)
        }

        if let tabBarController = baseVC as? UITabBarController {
            if let selectedVC = tabBarController.selectedViewController {
                return keyViewController(selectedVC)
            }
        }

        if let presented = baseVC?.presentedViewController {
            return keyViewController(presented)
        }

        return baseVC
    }
}
