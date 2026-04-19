//
//  StatusBar.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

/// A service for controlling the appearance and visibility of the
/// status bar.
///
/// Use `StatusBar` to override the status bar style, restore it to
/// the theme-appropriate default, or hide it entirely:
///
/// ```swift
/// StatusBar.overrideStyle(.lightContent)
///
/// // Later, restore the style based on the active theme:
/// StatusBar.restoreStyle()
/// ```
///
/// The service manages a dedicated window whose root view controller
/// owns the status bar appearance, ensuring that overrides apply
/// regardless of the current view controller hierarchy.
///
/// - Note: All members of `StatusBar` are isolated to the main actor.
@MainActor
public enum StatusBar {
    // MARK: - Properties

    private static var statusBarViewController: StatusBarViewController? {
        @Dependency(\.coreKit.ui) var coreUI: CoreKit.UI
        @Dependency(\.uiApplication.windows) var windows: [UIWindow]

        return (windows
            .first(where: {
                $0.tag == coreUI.semTag(for: "STATUS_BAR_WINDOW")
            }))?.rootViewController as? StatusBarViewController
    }

    // MARK: - Override Style

    /// Overrides the status bar style.
    ///
    /// The override remains in effect until ``restoreStyle()`` is
    /// called or a new override is applied.
    ///
    /// - Parameter style: The status bar style to apply.
    public static func overrideStyle(_ style: UIStatusBarStyle) {
        statusBarViewController?.statusBarStyle = style
    }

    // MARK: - Restore Style

    /// Restores the status bar style to the theme-appropriate
    /// default.
    ///
    /// The style is set to `lightContent` when dark mode is active,
    /// or `darkContent` otherwise.
    public static func restoreStyle() {
        statusBarViewController?.statusBarStyle = ThemeService.isDarkModeActive ? .lightContent : .darkContent
    }

    // MARK: - Set Is Hidden

    /// Shows or hides the status bar.
    ///
    /// - Parameter isHidden: Pass `true` to hide the status bar, or
    ///   `false` to show it.
    public static func setIsHidden(_ isHidden: Bool) {
        statusBarViewController?.isStatusBarHidden = isHidden
    }
}

final class StatusBarViewController: UIViewController {
    // MARK: - Properties

    var isStatusBarHidden: Bool = false {
        didSet { setNeedsStatusBarAppearanceUpdate() }
    }

    var statusBarStyle: UIStatusBarStyle = .default {
        didSet { setNeedsStatusBarAppearanceUpdate() }
    }

    // MARK: - Computed Properties

    override var preferredStatusBarStyle: UIStatusBarStyle { statusBarStyle }
    override var prefersStatusBarHidden: Bool { isStatusBarHidden }

    // MARK: - Init

    init() {
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@MainActor
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
