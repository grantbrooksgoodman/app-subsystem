//
//  CoreKit+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

/* Proprietary */
import AlertKit

extension CoreKit: AlertKit.PresentationDelegate {
    // MARK: - Properties

    /// All alert controllers currently presented in the app.
    public var presentedAlertControllers: [UIAlertController] {
        @Dependency(\.uiApplication) var uiApplication: UIApplication
        return uiApplication.presentedViewControllers.compactMap { $0 as? UIAlertController }
    }

    // MARK: - Methods

    /// Presents the given alert controller using the subsystem's UI
    /// layer.
    public func present(_ alertController: UIAlertController) {
        ui.present(
            alertController,
            animated: true,
            embedded: false,
            forced: false
        )
    }
}
