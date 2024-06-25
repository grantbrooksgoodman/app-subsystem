//
//  StatusBarStyle.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

public enum StatusBarStyle {
    // MARK: - Properties

    private static var statusBarWindow: UIWindow?

    // MARK: - Computed Properties

    private static var statusBarViewController: StatusBarViewController? { statusBarWindow?.rootViewController as? StatusBarViewController }

    // MARK: - Override

    public static func override(_ style: UIStatusBarStyle) {
        @Dependency(\.coreKit.ui) var coreUI: CoreKit.UI
        @Dependency(\.mainQueue) var mainQueue: DispatchQueue
        @Dependency(\.uiApplication.windows) var windows: [UIWindow]?

        mainQueue.async {
            defer { statusBarViewController?.statusBarStyle = style }
            guard let statusBarWindow = createStatusBarWindow() else { return }

            self.statusBarWindow = statusBarWindow
            windows?.filter { $0.tag != coreUI.semTag(for: "STATUS_BAR_WINDOW") }.forEach { $0.addSubview(statusBarWindow) }
        }
    }

    // MARK: - Restore

    public static func restore() {
        @Dependency(\.mainQueue) var mainQueue: DispatchQueue
        @Dependency(\.uiApplication.windows) var windows: [UIWindow]?

        mainQueue.async {
            statusBarViewController?.statusBarStyle = .default
            windows?.forEach { $0.removeSubviews(for: "STATUS_BAR_WINDOW") }
        }
    }

    // MARK: - Auxiliary

    private static func createStatusBarWindow() -> UIWindow? {
        @Dependency(\.coreKit.ui) var coreUI: CoreKit.UI
        @Dependency(\.uiApplication.mainWindow) var mainWindow: UIWindow?

        guard let windowScene = mainWindow?.windowScene else { return nil }

        let statusBarWindow: UIWindow = .init(windowScene: windowScene)
        statusBarWindow.isHidden = false
        statusBarWindow.isUserInteractionEnabled = false

        statusBarWindow.rootViewController = StatusBarViewController()
        statusBarWindow.tag = coreUI.semTag(for: "STATUS_BAR_WINDOW")
        statusBarWindow.windowLevel = .statusBar

        return statusBarWindow
    }
}

private class StatusBarViewController: UIViewController {
    // MARK: - Properties

    public var statusBarStyle: UIStatusBarStyle = .default {
        didSet { setNeedsStatusBarAppearanceUpdate() }
    }

    // MARK: - Computed Properties

    override public var preferredStatusBarStyle: UIStatusBarStyle { statusBarStyle }

    // MARK: - Init

    public init() {
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
