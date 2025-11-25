//
//  StatusBar.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

public enum StatusBar {
    // MARK: - Properties

    private static var statusBarViewController: StatusBarViewController? {
        @Dependency(\.coreKit.ui) var coreUI: CoreKit.UI
        @Dependency(\.uiApplication.windows) var windows: [UIWindow]

        return (windows
            .first(where: { $0.tag == coreUI.semTag(for: "STATUS_BAR_WINDOW") }))?
                    .rootViewController as? StatusBarViewController
    }

    // MARK: - Override Style

    public static func overrideStyle(_ style: UIStatusBarStyle) {
        @Dependency(\.mainQueue) var mainQueue: DispatchQueue
        mainQueue.async { statusBarViewController?.statusBarStyle = style }
    }

    // MARK: - Restore Style

    public static func restoreStyle() {
        @Dependency(\.mainQueue) var mainQueue: DispatchQueue
        mainQueue.async { statusBarViewController?.statusBarStyle = ThemeService.isDarkModeActive ? .lightContent : .darkContent }
    }

    // MARK: - Set Is Hidden

    public static func setIsHidden(_ isHidden: Bool) {
        @Dependency(\.mainQueue) var mainQueue: DispatchQueue
        mainQueue.async { statusBarViewController?.isStatusBarHidden = isHidden }
    }
}

final class StatusBarViewController: UIViewController {
    // MARK: - Properties

    public var isStatusBarHidden: Bool = false {
        didSet { setNeedsStatusBarAppearanceUpdate() }
    }

    public var statusBarStyle: UIStatusBarStyle = .default {
        didSet { setNeedsStatusBarAppearanceUpdate() }
    }

    // MARK: - Computed Properties

    override public var preferredStatusBarStyle: UIStatusBarStyle { statusBarStyle }
    override public var prefersStatusBarHidden: Bool { isStatusBarHidden }

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

extension UIUserInterfaceStyle {
    var statusBarStyle: UIStatusBarStyle {
        let adaptiveStyle: UIStatusBarStyle = ThemeService.isDarkModeActive ? .lightContent : .darkContent
        switch self {
        case .dark: return .lightContent
        case .light: return .darkContent
        case .unspecified: return adaptiveStyle
        @unknown default: return adaptiveStyle
        }
    }
}
