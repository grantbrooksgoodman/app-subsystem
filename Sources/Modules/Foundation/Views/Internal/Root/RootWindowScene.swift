//
//  RootWindowScene.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

public enum RootWindowScene {
    // MARK: - Properties

    private static let rootWindowScene = _RootWindowScene()

    // MARK: - Instantiate

    @MainActor
    public static func instantiate(_ scene: UIScene, rootView: any View) -> UIWindow {
        rootWindowScene.instantiate(scene, rootView: rootView)
    }

    // MARK: - Trait Collection Changed

    public static func traitCollectionChanged() {
        rootWindowScene.traitCollectionChanged()
    }
}

private final class _RootWindowScene: NSObject, UIGestureRecognizerDelegate {
    // MARK: - Dependencies

    @Dependency(\.build.milestone) private var buildMilestone: Build.Milestone
    @Dependency(\.coreKit.ui) private var coreUI: CoreKit.UI
    @Dependency(\.notificationCenter) private var notificationCenter: NotificationCenter

    // MARK: - Instantiate

    @MainActor
    fileprivate func instantiate(_ scene: UIScene, rootView: any View) -> UIWindow {
        guard let windowScene = scene as? UIWindowScene else { return .init() }

        // Root window

        let rootWindow = UIWindow(windowScene: windowScene)
        rootWindow.rootViewController = UIHostingController(rootView: RootWindow(rootView))
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
        )
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

        UIViewController.swizzleUIAlertControllerDismiss
        guard buildMilestone != .generalRelease else { return rootWindow }

        // Tap gesture recognizer

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

    fileprivate func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        Observables.rootViewTapped.trigger()
        return false
    }
}
