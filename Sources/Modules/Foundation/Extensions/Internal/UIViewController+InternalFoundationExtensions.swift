//
//  UIViewController+InternalFoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

extension UIViewController {
    // MARK: - Properties

    static let swizzleUIAlertControllerDismiss: Void = {
        guard let original = class_getInstanceMethod(UIAlertController.self, #selector(dismiss(animated:completion:))),
              let swizzled = class_getInstanceMethod(UIAlertController.self, #selector(_dismiss(animated:completion:))) else { return }
        method_exchangeImplementations(original, swizzled)
    }()

    /// Recursively traverses the presented view controller hierarchy to resolve all `presentedViewController` instances.
    var traversedPresentedViewControllers: [UIViewController] {
        var presentedViewControllers = [UIViewController]()
        var currentViewController = presentedViewController

        while let currentVC = currentViewController {
            presentedViewControllers.append(currentVC)
            currentViewController = currentVC.presentedViewController
        }

        return presentedViewControllers
    }

    /// Recursively traverses the presenting view controller hierarchy to resolve all `presentingViewController` instances.
    var traversedPresentingViewControllers: [UIViewController] {
        var presentingViewControllers = [UIViewController]()
        var currentViewController = presentingViewController

        while let currentVC = currentViewController {
            presentingViewControllers.append(currentVC)
            currentViewController = currentVC.presentingViewController
        }

        return presentingViewControllers
    }

    // MARK: - Methods

    @objc
    private func _dismiss(animated: Bool, completion: (() -> Void)?) {
        @Dependency(\.notificationCenter) var notificationCenter: NotificationCenter
        @Dependency(\.uiApplication) var uiApplication: UIApplication

        defer { _dismiss(animated: animated, completion: completion) }
        guard uiApplication.isPresentingAlertController else { return }
        notificationCenter.post(name: .uiAlertControllerDismissed, object: nil)
    }
}
