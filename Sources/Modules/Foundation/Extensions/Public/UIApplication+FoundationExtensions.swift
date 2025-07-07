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

    var firstResponder: UIView? {
        firstResponder()
    }

    var interfaceStyle: UIUserInterfaceStyle? {
        mainWindow?.overrideUserInterfaceStyle
    }

    static var iOS26IsAvailable: Bool {
        if #available(iOS 26, *) { return true }
        return false
    }

    static var iOS27IsAvailable: Bool {
        if #available(iOS 27, *) { return true }
        return false
    }

    static var isFullyV26Compatible: Bool {
        UIApplication.iOS26IsAvailable && UIApplication.isCompiledForV26OrLater
    }

    var isPresentingAlertController: Bool {
        presentedViewControllers.contains(where: { $0 is UIAlertController })
    }

    var isPresentingSheet: Bool {
        presentedViewControllers.contains(where: { $0.activePresentationController is UISheetPresentationController })
    }

    var keyViewController: UIViewController? {
        keyViewController(mainWindow?.rootViewController)
    }

    var mainScreen: UIScreen {
        mainWindow?.screen ?? .main
    }

    var mainWindow: UIWindow? {
        windows?.first(where: \.isKeyWindow)
    }

    /// Recursively resolves all view controllers (including parents & children) associated with all windows in all window scenes.
    var presentedViewControllers: [UIViewController] {
        presentedViewControllers()
    }

    /// Recursively resolves all views (including superviews & subviews) associated with all windows in all window scenes.
    var presentedViews: [UIView] {
        presentedViews()
    }

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

    var windows: [UIWindow]? {
        connectedScenes
            .first(where: { $0 is UIWindowScene })
            .flatMap { $0 as? UIWindowScene }?
            .windows
    }

    private var mainQueue: DispatchQueue { Dependency(\.mainQueue).wrappedValue }

    // MARK: - Methods

    func dismissAlertControllers(animated: Bool = true) {
        mainQueue.async {
            guard self.isPresentingAlertController else { return }
            self.presentedViewControllers
                .compactMap { $0 as? UIAlertController }
                .forEach { $0.dismiss(animated: animated) }
        }
    }

    func dismissSheets(animated: Bool = true) {
        mainQueue.async {
            guard self.isPresentingSheet else { return }
            self.presentedViewControllers
                .filter { $0.activePresentationController is UISheetPresentationController }
                .forEach { $0.dismiss(animated: animated) }
        }
    }

    func firstResponder(in view: UIView? = nil) -> UIView? {
        guard let view else { return presentedViews.first(where: { $0.isFirstResponder }) }
        guard !view.isFirstResponder else { return view }
        return view.traversedSubviews.first(where: { $0.isFirstResponder })
    }

    func overrideUserInterfaceStyle(_ style: UIUserInterfaceStyle) {
        mainQueue.async {
            self.presentedViewControllers.forEach { $0.overrideUserInterfaceStyle = style }
            self.windows?.forEach { $0.overrideUserInterfaceStyle = style }
        }
    }

    /// Recursively resolves all view controllers (including parents & children) associated with either the key window, or all windows in all window scenes.
    func presentedViewControllers(_ mainWindowOnly: Bool = false) -> [UIViewController] {
        var viewControllers = [UIViewController?]()

        guard mainWindowOnly else {
            guard let windows else { return [] }
            for window in windows {
                viewControllers.append(window.rootViewController)

                viewControllers.append(window.rootViewController?.presentedViewController)
                viewControllers.append(window.rootViewController?.presentingViewController)

                viewControllers.append(contentsOf: window.rootViewController?.ancestors() ?? [])
                viewControllers.append(contentsOf: window.rootViewController?.descendants() ?? [])

                viewControllers.append(contentsOf: window.rootViewController?.presentedViewController?.ancestors() ?? [])
                viewControllers.append(contentsOf: window.rootViewController?.presentedViewController?.descendants() ?? [])

                viewControllers.append(contentsOf: window.rootViewController?.presentingViewController?.ancestors() ?? [])
                viewControllers.append(contentsOf: window.rootViewController?.presentingViewController?.descendants() ?? [])
            }

            viewControllers.forEach { viewControllers.append(keyViewController($0)) }
            return viewControllers.compactMap { $0 }.unique
        }

        viewControllers = [
            mainWindow?.rootViewController,
            mainWindow?.rootViewController?.presentedViewController,
            mainWindow?.rootViewController?.presentingViewController,
        ]

        viewControllers += mainWindow?.rootViewController?.ancestors() ?? []
        viewControllers += mainWindow?.rootViewController?.descendants() ?? []

        viewControllers += mainWindow?.rootViewController?.presentedViewController?.ancestors() ?? []
        viewControllers += mainWindow?.rootViewController?.presentedViewController?.descendants() ?? []

        viewControllers += mainWindow?.rootViewController?.presentingViewController?.ancestors() ?? []
        viewControllers += mainWindow?.rootViewController?.presentingViewController?.descendants() ?? []

        viewControllers.forEach { viewControllers.append(keyViewController($0)) }
        return viewControllers.compactMap { $0 }.unique
    }

    /// Recursively resolves all views (including superviews & subviews) associated with either the key window, or all windows in all window scenes.
    func presentedViews(_ mainWindowOnly: Bool = false) -> [UIView] {
        let viewControllers = presentedViewControllers(mainWindowOnly)
        return viewControllers.compactMap(\.view) +
            viewControllers.compactMap(\.view).map(\.traversedSubviews).reduce([], +) +
            viewControllers.compactMap(\.view).map(\.traversedSuperviews).reduce([], +)
    }

    func resignFirstResponders(in view: UIView? = nil) {
        mainQueue.async {
            guard let view else { return self.presentedViews.filter { $0.isFirstResponder }.forEach { $0.resignFirstResponder() } }
            guard let firstResponder = self.firstResponder(in: view) else { return }
            firstResponder.resignFirstResponder()
        }
    }

    private static var isCompiledForV26OrLater: Bool {
        #if compiler(>=6.2)
        return true
        #else
        return false
        #endif
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
