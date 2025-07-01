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

    func firstSubview(for string: String) -> UIView? {
        @Dependency(\.coreKit.ui) var coreUI: CoreKit.UI
        return subviews.first(where: { $0.tag == coreUI.semTag(for: string) })
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
