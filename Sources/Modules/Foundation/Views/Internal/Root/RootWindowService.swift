//
//  RootWindowService.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

final class RootWindowService {
    // MARK: - Object Lifecycle

    deinit {
        @Dependency(\.notificationCenter) var notificationCenter: NotificationCenter

        notificationCenter.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )

        notificationCenter.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
    }

    // MARK: - Public

    func addKeyboardAppearanceObservers() {
        @Dependency(\.notificationCenter) var notificationCenter: NotificationCenter

        notificationCenter.addObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        ) { _ in
            Toast.updateFrameForKeyboardAppearance(0)
        }

        notificationCenter.addObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        ) { notification in
            guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
            Toast.updateFrameForKeyboardAppearance(keyboardFrame.cgRectValue.height)
        }
    }

    func startRaisingWindow() {
        @Dependency(\.coreKit) var core: CoreKit
        @Dependency(\.uiApplication.mainWindow) var mainWindow: UIWindow?

        defer {
            core.gcd.after(.milliseconds(50)) { self.startRaisingWindow() }
        }

        guard let mainWindow,
              let rootOverlayWindow = mainWindow.subviews.first(where: { $0.tag == core.ui.semTag(for: "ROOT_OVERLAY_WINDOW") }),
              mainWindow.subviews.last != rootOverlayWindow else { return }

        mainWindow.bringSubviewToFront(rootOverlayWindow)
    }
}

/* MARK: Dependency */

enum RootWindowServiceDependency: DependencyKey {
    static func resolve(_: DependencyValues) -> RootWindowService {
        .init()
    }
}

extension DependencyValues {
    var rootWindowService: RootWindowService {
        get { self[RootWindowServiceDependency.self] }
        set { self[RootWindowServiceDependency.self] = newValue }
    }
}
