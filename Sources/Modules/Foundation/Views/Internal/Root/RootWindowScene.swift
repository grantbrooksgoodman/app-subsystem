//
//  RootWindowScene.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/// The entry point for creating and managing the app's
/// window hierarchy.
///
/// `RootWindowScene` creates a three-window structure
/// during scene setup: a root window that hosts the app's
/// SwiftUI content, an overlay window for toasts and the
/// build-info overlay, and a status bar window. Call
/// ``instantiate(_:rootView:)`` from the scene delegate's
/// `scene(_:willConnectTo:options:)` implementation:
///
/// ```swift
/// window = RootWindowScene.instantiate(
///     scene,
///     rootView: ContentView()
/// )
/// ```
///
/// Forward trait collection changes from the scene
/// delegate's
/// `windowScene(_:didUpdate:interfaceOrientation:traitCollection:)`
/// implementation:
///
///     RootWindowScene.traitCollectionChanged()
///
/// - Important: Do not create additional `UIWindow`
///   instances. The subsystem manages the full window
///   hierarchy.
///
/// - Note: The window hierarchy is configured with a
///   left-to-right layout direction.
@MainActor
public enum RootWindowScene {
    // MARK: - Properties

    private static let rootWindowScene = _RootWindowScene()

    // MARK: - Instantiate

    /// Creates the app's window hierarchy for the specified
    /// scene.
    ///
    /// This method creates the root content window, an
    /// overlay window for toasts and the build-info overlay,
    /// and a status bar window. Store the returned window in
    /// the scene delegate's `window` property.
    ///
    /// - Parameters:
    ///   - scene: The scene provided by UIKit in the scene
    ///     delegate callback.
    ///   - rootView: The root SwiftUI view for the app.
    ///
    /// - Returns: The root window for the scene.
    public static func instantiate(
        _ scene: UIScene,
        rootView: any View
    ) -> UIWindow {
        rootWindowScene.instantiate(
            scene,
            rootView: rootView
        )
    }

    // MARK: - Trait Collection Changed

    /// Notifies the subsystem that the interface environment
    /// changed.
    ///
    /// Call this method from the scene delegate's
    /// `windowScene(_:didUpdate:interfaceOrientation:traitCollection:)`
    /// implementation. The subsystem updates themed views in
    /// response.
    public static func traitCollectionChanged() {
        rootWindowScene.traitCollectionChanged()
    }
}

@MainActor
private final class _RootWindowScene: NSObject, UIGestureRecognizerDelegate {
    // MARK: - Dependencies

    @Dependency(\.build.milestone) private var buildMilestone: Build.Milestone
    @Dependency(\.coreKit.ui) private var coreUI: CoreKit.UI
    @Dependency(\.notificationCenter) private var notificationCenter: NotificationCenter

    // MARK: - Instantiate

    fileprivate func instantiate(
        _ scene: UIScene,
        rootView: any View
    ) -> UIWindow {
        guard let windowScene = scene as? UIWindowScene else { return .init() }

        // Root window

        let rootWindow = UIWindow(windowScene: windowScene)
        rootWindow.rootViewController = UIHostingController(
            rootView: RootWindow(rootView)
                .environment(\.layoutDirection, .leftToRight)
        )
        rootWindow.semanticContentAttribute = .forceLeftToRight
        rootWindow.makeKeyAndVisible()
        rootWindow.tag = coreUI.semTag(for: "ROOT_WINDOW")

        // Root overlay window

        let rootOverlayWindow: UIWindow = UIApplication.iOS27IsAvailable ? UIWindow() : PassthroughWindow(windowScene: windowScene)
        if UIApplication.iOS27IsAvailable {
            rootOverlayWindow.frame = RootOverlayView.fallbackFrame
        }

        rootOverlayWindow.rootViewController = UIHostingController(
            rootView: RootOverlayView(
                .init(
                    initialState: .init(),
                    reducer: RootOverlayReducer()
                )
            )
            .environment(\.layoutDirection, .leftToRight)
        )
        rootOverlayWindow.semanticContentAttribute = .forceLeftToRight
        rootOverlayWindow.tag = coreUI.semTag(for: "ROOT_OVERLAY_WINDOW")

        rootOverlayWindow.backgroundColor = .clear
        rootOverlayWindow.rootViewController?.view.backgroundColor = .clear

        rootOverlayWindow.isHidden = false
        rootOverlayWindow.isUserInteractionEnabled = true

        rootWindow.addSubview(rootOverlayWindow)

        // Status bar window

        let statusBarWindow: UIWindow = .init(windowScene: windowScene)

        statusBarWindow.rootViewController = StatusBarViewController()
        statusBarWindow.tag = coreUI.semTag(for: "STATUS_BAR_WINDOW")
        statusBarWindow.windowLevel = .statusBar

        statusBarWindow.isHidden = false
        statusBarWindow.isUserInteractionEnabled = false

        rootWindow.addSubview(statusBarWindow)

        // Auxiliary layout

        UINavigationBar.appearance().semanticContentAttribute = .forceLeftToRight
        UIView.appearance().semanticContentAttribute = .forceLeftToRight

        UIViewController.swizzleUIAlertControllerDismiss

        // Tap gesture recognizer

        guard buildMilestone != .generalRelease else { return rootWindow }

        let tapGesture = UITapGestureRecognizer(target: self, action: nil)
        tapGesture.delegate = self
        rootWindow.addGestureRecognizer(tapGesture)

        return rootWindow
    }

    // MARK: - Trait Collection Changed

    fileprivate func traitCollectionChanged() {
        notificationCenter.post(.init(name: .traitCollectionChangedNotification))
        Observables.themedViewAppearanceChanged.trigger()
    }

    // MARK: - UIGestureRecognizer

    fileprivate func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        Observables.rootViewTapped.trigger()
        return false
    }
}
