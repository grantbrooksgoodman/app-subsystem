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
    /// A service for displaying and dismissing a heads-up display
    /// (HUD) overlay.
    ///
    /// Use `HUD` to give the user lightweight, non-blocking feedback
    /// during short operations:
    ///
    /// ```swift
    /// @Dependency(\.coreKit) var core: CoreKit
    ///
    /// core.hud.showProgress(text: "Saving...")
    /// // ... perform work ...
    /// core.hud.showSuccess(text: "Saved")
    /// ```
    ///
    /// For longer operations that should prevent user interaction,
    /// pass `isModal: true` to ``showProgress(text:after:isModal:)``.
    ///
    /// Always call ``hide(after:)`` when the operation finishes to
    /// restore interaction.
    struct HUD: Sendable {
        // MARK: - Types

        /// The image displayed inside a HUD flash.
        public enum HUDImage: Sendable {
            /// A success checkmark.
            case success

            /// An exclamation mark.
            case exclamation
        }

        // MARK: - Properties

        static let shared = HUD()

        static let isBlockingUserInteraction = LockIsolated(false)

        // MARK: - Init

        private init() {}

        // MARK: - Methods

        /// Briefly displays the HUD with an image and optional text.
        ///
        /// The HUD appears momentarily and dismisses itself
        /// automatically.
        ///
        /// - Parameters:
        ///   - text: An optional message to display below the image.
        ///   - image: The image to show in the HUD.
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

        /// Hides the HUD and restores user interaction.
        ///
        /// The HUD is dismissed after the specified delay. If the
        /// HUD was presented modally, user interaction is
        /// unblocked automatically.
        ///
        /// - Parameter delay: The duration to wait before removing
        ///   the HUD. The default is 250 milliseconds.
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

        /// Shows a spinning activity indicator.
        ///
        /// - Parameters:
        ///   - text: An optional message to display below the
        ///     spinner.
        ///   - delay: An optional duration to wait before showing
        ///     the HUD. Pass `nil` to show immediately.
        ///   - isModal: Pass `true` to block user interaction while
        ///     the HUD is visible. Call ``hide(after:)`` to restore
        ///     interaction when the operation completes.
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

        /// Shows a success indicator with an optional message.
        ///
        /// The HUD dismisses itself automatically after a brief
        /// display.
        ///
        /// - Parameter text: An optional message to display below
        ///   the success indicator.
        public func showSuccess(
            text: String? = nil
        ) {
            Task { @MainActor in
                ProgressHUD.showSucceed(text)
            }
        }
    }
}
