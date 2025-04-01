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
