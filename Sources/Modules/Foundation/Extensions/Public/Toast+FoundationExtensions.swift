//
//  Toast+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

public extension Toast {
    // MARK: - Properties

    private static var isHidden = true
    private static var keyboardHeight: CGFloat = 0

    // MARK: - Methods

    static func show(_ toast: Toast, onTap: (() -> Void)? = nil) {
        Task { @MainActor in
            guard UIApplication.iOS19IsAvailable else {
                Observables.rootViewToast.value = toast
                Observables.rootViewToastAction.value = onTap
                return
            }

            guard isHidden else {
                Task.delayed(by: .seconds(1)) { show(toast, onTap: onTap) }
                return
            }

            @Dependency(\.uiApplication.mainWindow) var mainWindow: UIWindow?

            guard let rootOverlayWindow = mainWindow?.firstSubview(for: "ROOT_OVERLAY_WINDOW"),
                  let overlayFrame = frame(toast.type.appearanceEdge ?? .top) else { return }

            Observables.rootViewToast.value = toast
            Observables.rootViewToastAction.value = onTap

            rootOverlayWindow.frame = overlayFrame
            rootOverlayWindow.isUserInteractionEnabled = true

            isHidden = false
        }
    }

    static func hide() {
        Task { @MainActor in
            guard UIApplication.iOS19IsAvailable else {
                Observables.rootViewToast.value = nil
                Observables.rootViewToastAction.value = nil
                return
            }

            @Dependency(\.uiApplication.mainWindow) var mainWindow: UIWindow?

            guard !isHidden,
                  let rootOverlayWindow = mainWindow?.firstSubview(for: "ROOT_OVERLAY_WINDOW") else { return }

            Observables.rootViewToast.value = nil
            Observables.rootViewToastAction.value = nil

            rootOverlayWindow.frame = .zero
            rootOverlayWindow.isUserInteractionEnabled = false

            isHidden = true
        }
    }

    package static func updateFrameForKeyboardAppearance(_ keyboardHeight: CGFloat) {
        Task { @MainActor in
            @Dependency(\.uiApplication.mainWindow) var mainWindow: UIWindow?

            self.keyboardHeight = keyboardHeight
            guard !isHidden,
                  let rootOverlayWindow = mainWindow?.firstSubview(for: "ROOT_OVERLAY_WINDOW"),
                  let overlayFrame = frame(Observables.rootViewToast.value?.type.appearanceEdge ?? .top) else { return }

            rootOverlayWindow.frame = overlayFrame
            rootOverlayWindow.isUserInteractionEnabled = true
        }
    }

    @MainActor
    private static func frame(_ appearanceEdge: Toast.AppearanceEdge) -> CGRect? {
        @Dependency(\.uiApplication.mainWindow) var mainWindow: UIWindow?
        guard let mainWindow else { return nil }

        let size: CGSize = .init(
            width: mainWindow.bounds.width,
            height: mainWindow.bounds.height / 8
        )

        let bottomSafeAreaInsets = mainWindow.safeAreaInsets.bottom < 30 ? (30 + (30 - mainWindow.safeAreaInsets.bottom)) : mainWindow.safeAreaInsets.bottom
        let topSafeAreaInsets = mainWindow.safeAreaInsets.top < 30 ? (30 + (30 - mainWindow.safeAreaInsets.top)) : mainWindow.safeAreaInsets.top

        var bottomEdgeOrigin: CGPoint = .init(
            x: 0,
            y: mainWindow.bounds.maxY - (size.height + bottomSafeAreaInsets + keyboardHeight)
        )

        let topEdgeOrigin: CGPoint = .init(
            x: 0,
            y: topSafeAreaInsets
        )

        if keyboardHeight > 0 {
            bottomEdgeOrigin.y += 30
        }

        return .init(origin: appearanceEdge == .bottom ? bottomEdgeOrigin : topEdgeOrigin, size: size)
    }
}
