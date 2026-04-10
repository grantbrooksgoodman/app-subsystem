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
    struct HUD: Sendable {
        // MARK: - Types

        public enum HUDImage: Sendable {
            case success
            case exclamation
        }

        // MARK: - Properties

        static let shared = HUD()

        static let isBlockingUserInteraction = LockIsolated<Bool>(wrappedValue: false)

        // MARK: - Init

        private init() {}

        // MARK: - Methods

        public func flash(
            _ text: String? = nil,
            image: HUDImage
        ) {
            Task { @MainActor in
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
        }

        public func hide(
            after delay: Duration = .milliseconds(250)
        ) {
            Task { @MainActor in
                HUD.isBlockingUserInteraction.wrappedValue = false
                UI.shared.unblockUserInteraction()
                ProgressHUD.dismiss()
                try? await Task.sleep(for: delay)
                ProgressHUD.remove()
            }
        }

        public func showProgress(
            text: String? = nil,
            after delay: Duration? = nil,
            isModal: Bool = false
        ) {
            Task { @MainActor in
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
                try? await Task.sleep(for: delay)
                showHUD()
            }
        }

        public func showSuccess(
            text: String? = nil
        ) {
            Task { @MainActor in
                ProgressHUD.showSucceed(text)
            }
        }
    }
}
