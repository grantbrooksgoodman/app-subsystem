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
        get async {
            let buildInfoOverlayWasHidden = BuildInfoOverlay.isHidden
            if buildInfoOverlayWasHidden {
                BuildInfoOverlay.show(persistSetting: false)
                // Yield to allow the Observable notification and SwiftUI
                // rendering pipeline to process the visibility change.
                try? await Task.sleep(for: .milliseconds(100))
            }

            defer {
                if buildInfoOverlayWasHidden {
                    BuildInfoOverlay.hide(persistSetting: false)
                }
            }

            #if targetEnvironment(simulator)
            let snapshotView = mainScreen.snapshotView(afterScreenUpdates: true)
            snapshotView.bounds = .init(origin: .zero, size: mainScreen.bounds.size)

            let renderer = UIGraphicsImageRenderer(size: mainScreen.bounds.size)
            return renderer.image { _ in
                snapshotView.drawHierarchy(
                    in: mainScreen.bounds,
                    afterScreenUpdates: true
                )
            }
            #else
            guard let mainWindow else { return nil }
            var image: UIImage?

            UIGraphicsBeginImageContextWithOptions(
                mainWindow.layer.frame.size,
                false,
                mainWindow.screen.scale
            )

            guard let context = UIGraphicsGetCurrentContext() else { return nil }
            mainWindow.layer.render(in: context)

            image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return image
            #endif
        }
    }

    /// All windows across all connected scenes.
    var windows: [UIWindow] {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
    }

    private static let bundleRequiresPreV26Design: Bool = {
        @Dependency(\.mainBundle) var mainBundle: Bundle
        return mainBundle.object(
            forInfoDictionaryKey: "UIDesignRequiresCompatibility"
        ) as? Bool ?? false
    }()

    private static let isCompiledForV26OrLater: Bool = {
        #if compiler(>=6.2)
        return true
        #else
        return false
        #endif
    }()

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
    ///
    /// When no view is specified, the method escalates through
    /// increasingly aggressive dismissal strategies until no
    /// first responder remains:
    ///
    /// 1. Direct resignation of every discovered first responder.
    /// 2. Forced `endEditing(_:)` on every window.
    /// 3. Responder-chain action dispatch.
    /// 4. First-responder transfer to a temporary text field.
    ///
    /// When `repeatingFor` is specified, the method re-attempts
    /// dismissal every 100 milliseconds for the given duration,
    /// regardless of whether a first responder exists at the time
    /// of each attempt.
    func resignFirstResponders(
        in view: UIView? = nil,
        repeatingFor duration: Duration? = nil
    ) {
        resignFirstResponders(in: view)

        guard let duration else { return }

        let startDate = Date.now
        Task { @MainActor in
            while true {
                try? await Task.sleep(for: .milliseconds(100))
                guard Date.now.milliseconds(
                    from: startDate
                ) < Int(duration.milliseconds) else { return }
                resignFirstResponders(in: view)
            }
        }
    }

    private func resignFirstResponders(in view: UIView?) {
        if let view {
            guard let firstResponder = firstResponder(in: view) else { return }
            firstResponder.resignFirstResponder()
            return
        }

        // Direct resignation of all discovered first responders.
        presentedViews
            .filter(\.isFirstResponder)
            .forEach { $0.resignFirstResponder() }

        guard firstResponder != nil else { return }

        // Forced end-editing on every window.
        for window in windows {
            window.endEditing(true)
        }

        guard firstResponder != nil else { return }

        // Responder-chain action dispatch.
        sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )

        guard firstResponder != nil else { return }

        // Last resort: force first-responder transfer to a
        // temporary text field, then resign it.
        guard let mainWindow else { return }

        let textField = UITextField(frame: .zero)
        mainWindow.addSubview(textField)

        textField.becomeFirstResponder()
        textField.resignFirstResponder()
        textField.removeFromSuperview()
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
