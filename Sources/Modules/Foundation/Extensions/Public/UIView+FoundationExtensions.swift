//
//  UIView+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

@MainActor
public extension UIView {
    // MARK: - Properties

    /// A string describing the view's type.
    var descriptor: String { .init(type(of: self)) }

    /// All subviews in the hierarchy below this view, resolved
    /// recursively.
    var traversedSubviews: [UIView] {
        var subviews = [UIView]()
        func getSubviews(for view: UIView) {
            subviews.append(contentsOf: view.subviews)
            view.subviews.forEach { getSubviews(for: $0) }
        }
        getSubviews(for: self)
        return subviews
    }

    /// All superviews above this view, resolved recursively.
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

    /// Adds the gesture recognizer, or enables it if it is already
    /// attached.
    func addOrEnable(_ gestureRecognizer: UIGestureRecognizer) {
        guard let existingGestureRecognizer = gestureRecognizers?
            .first(where: { $0 == gestureRecognizer }) else { return addGestureRecognizer(gestureRecognizer) }
        existingGestureRecognizer.isEnabled = true
    }

    /// Returns the first direct subview whose tag matches the
    /// semantic tag for the given string.
    func firstSubview(for string: String) -> UIView? {
        @Dependency(\.coreKit.ui) var coreUI: CoreKit.UI
        return subviews.first(where: { $0.tag == coreUI.semTag(for: string) })
    }

    /// Removes all direct subviews matching the semantic tag for the
    /// given string.
    func removeSubviews(
        for string: String,
        animated: Bool = true
    ) {
        let subviews = subviews(for: string)
        guard animated else {
            return subviews.forEach { $0.removeFromSuperview() }
        }

        for subview in subviews {
            UIView.animate(withDuration: 0.2) {
                subview.alpha = 0
            } completion: { _ in
                subview.removeFromSuperview()
            }
        }
    }

    /// Returns all direct subviews matching the semantic tag for
    /// the given string.
    func subviews(for string: String) -> [UIView] {
        @Dependency(\.coreKit.ui) var coreUI: CoreKit.UI
        return subviews.filter { $0.tag == coreUI.semTag(for: string) }
    }
}
