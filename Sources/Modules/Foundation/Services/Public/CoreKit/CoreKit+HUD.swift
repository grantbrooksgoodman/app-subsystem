//
//  CoreKit+HUD.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

public extension CoreKit {
    @MainActor
    struct HUD: Sendable {
        // MARK: - Types

        public enum HUDImage {
            case success
            case exclamation
        }

        // MARK: - Dependencies

        @Dependency(\.uiApplication) private var uiApplication: UIApplication

        // MARK: - Properties

        static let shared = HUD()

        static let isBlockingUserInteraction = LockIsolated<Bool>(wrappedValue: false)

        // MARK: - Init

        private init() {}

        // MARK: - Methods

        public func flash(_ text: String? = nil, image: HUDImage) {
            var alertIcon: AlertIcon?
            var animatedIcon: AnimatedIcon?

            switch image {
            case .success:
                animatedIcon = .succeed
            case .exclamation:
                alertIcon = .exclamation
            }

            var resolvedText = text
            if let text,
               text.hasSuffix(".") {
                resolvedText = text.dropSuffix()
            }

            guard let alertIcon else {
                guard let animatedIcon else { return }
                return ProgressHUD.show(
                    resolvedText,
                    icon: animatedIcon,
                    interaction: true
                )
            }

            ProgressHUD.show(
                resolvedText,
                icon: alertIcon,
                interaction: true
            )
        }

        public func hide(after delay: Duration = .milliseconds(250)) {
            HUD.isBlockingUserInteraction.wrappedValue = false
            UI.shared.unblockUserInteraction()
            ProgressHUD.dismiss()
            GCD.shared.after(delay) {
                Task { @MainActor in
                    ProgressHUD.remove()
                }
            }
        }

        public func showProgress(
            text: String? = nil,
            after delay: Duration? = nil,
            isModal: Bool = false
        ) {
            @Sendable
            func showHUD() {
                Task { @MainActor in
                    ProgressHUD.show(text)
                    guard isModal else { return }
                    HUD.isBlockingUserInteraction.wrappedValue = true
                    UI.shared.blockUserInteraction(dismissSheets: false)
                }
            }

            guard let delay else { return showHUD() }
            GCD.shared.after(delay) { showHUD() }
        }

        public func showSuccess(text: String? = nil) {
            ProgressHUD.showSucceed(text)
        }
    }
}
