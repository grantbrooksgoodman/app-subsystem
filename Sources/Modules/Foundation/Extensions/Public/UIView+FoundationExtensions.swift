//
//  UIView+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

public extension UIView {
    // MARK: - Types

    struct OverlayActivityIndicatorConfiguration {
        /* MARK: Properties */

        public let color: UIColor
        public let style: UIActivityIndicatorView.Style

        /* MARK: Computed Properties */

        public static let largeWhite: OverlayActivityIndicatorConfiguration = .init(style: .large, color: .white)

        /* MARK: Init */

        public init(
            style: UIActivityIndicatorView.Style,
            color: UIColor
        ) {
            self.style = style
            self.color = color
        }
    }

    // MARK: - Properties

    /// Recursively traverses the view hierarchy to resolve all associated subviews.
    var traversedSubviews: [UIView] {
        var subviews = [UIView]()
        func getSubviews(for view: UIView) {
            subviews.append(contentsOf: view.subviews)
            view.subviews.forEach { getSubviews(for: $0) }
        }
        getSubviews(for: self)
        return subviews
    }

    /// Recursively traverses the view hierarchy to resolve all associated superviews.
    var traversedSuperviews: [UIView] {
        var superviews = [UIView]()
        var currentView = self
        while let superview = currentView.superview {
            superviews.append(superview)
            currentView = superview
        }
        return superviews
    }

    @LockIsolated internal private(set) static var isBlockingUserInteraction = false

    // MARK: - Methods

    func addOrEnable(_ gestureRecognizer: UIGestureRecognizer) {
        guard let existingGestureRecognizer = gestureRecognizers?
            .first(where: { $0 == gestureRecognizer }) else { return addGestureRecognizer(gestureRecognizer) }
        existingGestureRecognizer.isEnabled = true
    }

    func addOverlay(
        alpha: CGFloat = 1,
        activityIndicator indicatorConfig: OverlayActivityIndicatorConfiguration?,
        backgroundColor: UIColor = .black,
        blurStyle: UIBlurEffect.Style? = nil,
        isModal: Bool = true
    ) {
        Task { @MainActor in
            @Dependency(\.coreKit) var core: CoreKit
            @Dependency(\.uiApplication) var uiApplication: UIApplication

            if isModal {
                UIView.isBlockingUserInteraction = true
                core.ui.blockUserInteraction()
                uiApplication
                    .windows?
                    .first(where: { $0.tag == core.ui.semTag(for: "ROOT_OVERLAY_WINDOW") })?
                    .alpha = 0
            }

            let overlayView = blurStyle == nil ? UIView() : UIVisualEffectView(effect: UIBlurEffect(style: blurStyle!))
            overlayView.alpha = alpha
            overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            overlayView.backgroundColor = backgroundColor
            overlayView.frame = bounds
            overlayView.tag = core.ui.semTag(for: "OVERLAY_VIEW")
            addSubview(overlayView)

            guard let indicatorConfig else { return }

            let indicatorView = UIActivityIndicatorView(style: indicatorConfig.style)
            indicatorView.center = overlayView.center
            indicatorView.color = indicatorConfig.color
            indicatorView.startAnimating()
            indicatorView.tag = core.ui.semTag(for: "OVERLAY_VIEW_ACTIVITY_INDICATOR")
            addSubview(indicatorView)
        }
    }

    func firstSubview(for string: String) -> UIView? {
        @Dependency(\.coreKit.ui) var coreUI: CoreKit.UI
        return subviews.first(where: { $0.tag == coreUI.semTag(for: string) })
    }

    func removeOverlay(animated: Bool = true) {
        Task { @MainActor in
            @Dependency(\.coreKit) var core: CoreKit
            @Dependency(\.uiApplication) var uiApplication: UIApplication

            @MainActor
            func removeViews() {
                overlayViews.forEach { $0.removeFromSuperview() }
                activityIndicatorViews.forEach { $0.removeFromSuperview() }

                UIView.isBlockingUserInteraction = false
                core.ui.unblockUserInteraction()
                uiApplication
                    .windows?
                    .first(where: { $0.tag == core.ui.semTag(for: "ROOT_OVERLAY_WINDOW") })?
                    .alpha = 1
            }

            let overlayViews = subviews(for: "OVERLAY_VIEW")
            let activityIndicatorViews = subviews(for: "OVERLAY_VIEW_ACTIVITY_INDICATOR")

            guard animated else { return removeViews() }

            UIView.animate(withDuration: 0.2) {
                overlayViews.forEach { $0.alpha = 0 }
                activityIndicatorViews.forEach { $0.alpha = 0 }
            } completion: { _ in
                removeViews()
            }
        }
    }

    func removeSubviews(for string: String, animated: Bool = true) {
        Task { @MainActor in
            let subviews = subviews(for: string)

            guard animated else {
                subviews.forEach { $0.removeFromSuperview() }
                return
            }

            for subview in subviews {
                UIView.animate(withDuration: 0.2) {
                    subview.alpha = 0
                } completion: { _ in
                    subview.removeFromSuperview()
                }
            }
        }
    }

    func subviews(for string: String) -> [UIView] {
        @Dependency(\.coreKit.ui) var coreUI: CoreKit.UI
        return subviews.filter { $0.tag == coreUI.semTag(for: string) }
    }
}
