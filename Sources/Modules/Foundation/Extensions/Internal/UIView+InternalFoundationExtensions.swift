//
//  UIView+InternalFoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

extension UIView {
    // MARK: - Properties

    @LockIsolated private(set) static var isBlockingUserInteraction = false

    // MARK: - Methods

    func addOverlay(
        alpha: CGFloat,
        activityIndicator indicatorConfig: CoreKit.UI.OverlayActivityIndicatorConfiguration?,
        backgroundColor: UIColor,
        blurStyle: UIBlurEffect.Style?,
        isModal: Bool
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

    func removeOverlay(animated: Bool) {
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
}
