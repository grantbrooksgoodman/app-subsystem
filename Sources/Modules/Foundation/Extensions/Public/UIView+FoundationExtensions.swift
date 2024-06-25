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

    // MARK: - Methods

    func addOrEnable(_ gestureRecognizer: UIGestureRecognizer) {
        guard let existingGestureRecognizer = gestureRecognizers?
            .first(where: { $0 == gestureRecognizer }) else { return addGestureRecognizer(gestureRecognizer) }
        existingGestureRecognizer.isEnabled = true
    }

    func addOverlay(
        alpha: CGFloat = 0.5,
        activityIndicator indicatorConfig: (style: UIActivityIndicatorView.Style, color: UIColor)? = (.large, .white),
        blurStyle: UIBlurEffect.Style? = nil,
        color: UIColor? = nil,
        name tag: String? = nil
    ) {
        @Dependency(\.coreKit.ui) var coreUI: CoreKit.UI

        let overlayView = blurStyle == nil ? UIView() : UIVisualEffectView(effect: UIBlurEffect(style: blurStyle!))
        overlayView.alpha = alpha
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlayView.backgroundColor = color ?? .black
        overlayView.frame = bounds
        overlayView.tag = coreUI.semTag(for: tag ?? "OVERLAY_VIEW")
        addSubview(overlayView)

        guard let indicatorConfig else { return }

        let indicatorView = UIActivityIndicatorView(style: indicatorConfig.style)
        indicatorView.center = overlayView.center
        indicatorView.color = indicatorConfig.color
        indicatorView.startAnimating()
        indicatorView.tag = coreUI.semTag(for: "OVERLAY_VIEW_ACTIVITY_INDICATOR")
        addSubview(indicatorView)
    }

    func firstSubview(for string: String) -> UIView? {
        @Dependency(\.coreKit.ui) var coreUI: CoreKit.UI
        return subviews.first(where: { $0.tag == coreUI.semTag(for: string) })
    }

    func removeOverlay(name tag: String? = nil, animated: Bool = true) {
        let overlayViews = subviews(for: tag ?? "OVERLAY_VIEW")
        let activityIndicatorViews = subviews(for: "OVERLAY_VIEW_ACTIVITY_INDICATOR")

        Task { @MainActor in
            UIView.animate(withDuration: 0.2) {
                overlayViews.forEach { $0.alpha = 0 }
                activityIndicatorViews.forEach { $0.alpha = 0 }
            } completion: { _ in
                overlayViews.forEach { $0.removeFromSuperview() }
                activityIndicatorViews.forEach { $0.removeFromSuperview() }
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
