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

    private static var statusBarViewController: StatusBarViewController? { statusBarWindow?.rootViewController as? StatusBarViewController }
    private static var statusBarWindow: UIWindow? {
        @Dependency(\.coreKit.ui) var coreUI: CoreKit.UI
        @Dependency(\.uiApplication.windows) var windows: [UIWindow]?
        return windows?.first(where: { $0.tag == coreUI.semTag(for: "STATUS_BAR_WINDOW") })
    }

    // MARK: - Override

    public static func override(_ style: UIStatusBarStyle) {
        @Dependency(\.mainQueue) var mainQueue: DispatchQueue
        mainQueue.async { statusBarViewController?.statusBarStyle = style }
    }

    // MARK: - Restore

    public static func restore() {
        @Dependency(\.mainQueue) var mainQueue: DispatchQueue
        mainQueue.async { statusBarViewController?.statusBarStyle = ThemeService.isDarkModeActive ? .lightContent : .darkContent }
    }
}

final class StatusBarViewController: UIViewController {
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
