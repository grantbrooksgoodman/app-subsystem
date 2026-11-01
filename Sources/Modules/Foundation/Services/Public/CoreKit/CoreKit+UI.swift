//
//  CoreKit+UI.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

public extension CoreKit {
    /// User interface services for overlays, view-controller
    /// presentation, and appearance management.
    ///
    /// All members of `UI` are isolated to the main actor.
    @MainActor
    struct UI {
        // MARK: - Constants Accessors

        private typealias Floats = FoundationConstants.CGFloats.CoreKitUI

        // MARK: - Types

        /// The appearance of the activity indicator shown inside a
        /// full-screen overlay.
        public struct OverlayActivityIndicatorConfiguration: Sendable {
            /* MARK: Properties */

            let color: UIColor
            let style: UIActivityIndicatorView.Style

            /* MARK: Computed Properties */

            /// A large, white activity indicator.
            public static let largeWhite: OverlayActivityIndicatorConfiguration = .init(
                style: .large,
                color: .white
            )

            /* MARK: Init */

            /// Creates an overlay activity indicator configuration.
            ///
            /// - Parameters:
            ///   - style: The visual style of the indicator.
            ///   - color: The color of the indicator.
            public init(
                style: UIActivityIndicatorView.Style,
                color: UIColor
            ) {
                self.style = style
                self.color = color
            }
        }

        enum InteractionBlockingReason {
            case modalHUD
            case modalOverlay
        }

        // MARK: - Dependencies

        @Dependency(\.userDefaults) private var defaults: UserDefaults
        @Dependency(\.uiApplication) private var uiApplication: UIApplication

        // MARK: - Properties

        static let shared = UI()

        private static let blockingReasons = LockIsolated(Set<InteractionBlockingReason>())
        private static let dismissalTask = LockIsolated<Task<Void, Never>?>(nil)
        private static let semTags = LockIsolated([String: Int]())
        private static let sheetDismissingReasons = LockIsolated(Set<InteractionBlockingReason>())

        // MARK: - Computed Properties

        static var isBlockingUserInteraction: Bool {
            !blockingReasons.wrappedValue.isEmpty
        }

        // MARK: - Init

        private init() {}

        // MARK: - Full Screen Overlay

        /// Adds a full-screen overlay to the main window.
        ///
        /// Use an overlay to dim the interface or indicate a blocking
        /// operation. Optionally include an activity indicator and a
        /// blur effect.
        ///
        /// - Parameters:
        ///   - alpha: The opacity of the overlay. The default is `1`.
        ///   - indicatorConfig: An optional activity indicator
        ///     configuration. Pass `nil` to omit the indicator.
        ///   - backgroundColor: The overlay's background color. The
        ///     default is black.
        ///   - blurStyle: An optional blur effect style applied
        ///     behind the overlay.
        ///   - isModal: Pass `true` to block user interaction while
        ///     the overlay is visible. The default is `true`.
        public func addOverlay(
            alpha: CGFloat = 1,
            activityIndicator indicatorConfig: OverlayActivityIndicatorConfiguration?,
            backgroundColor: UIColor = .black,
            blurStyle: UIBlurEffect.Style? = nil,
            isModal: Bool = true
        ) {
            uiApplication.mainWindow?.addOverlay(
                alpha: alpha,
                activityIndicator: indicatorConfig,
                backgroundColor: backgroundColor,
                blurStyle: blurStyle,
                isModal: isModal
            )
        }

        /// Removes the full-screen overlay from the main window.
        ///
        /// - Parameter animated: Pass `true` to fade the overlay out.
        ///   The default is `true`.
        public func removeOverlay(animated: Bool = true) {
            uiApplication.mainWindow?.removeOverlay(animated: animated)
        }

        // MARK: - Glass Tinting

        /// Enables or disables glass tinting on navigation bar items.
        ///
        /// The preference is persisted to `UserDefaults` and takes
        /// effect immediately.
        ///
        /// - Parameter isEnabled: Pass `true` to enable glass
        ///   tinting, or `false` to disable it.
        public func toggleGlassTinting(on isEnabled: Bool) {
            @Persistent(.isGlassTintingEnabled) var isGlassTintingEnabled: Bool?

            isGlassTintingEnabled = isEnabled
            defaults.synchronize() // NIT: Trying to force sync.

            NavigationBar.removeAllItemGlassTint()
            RootWindowScene.traitCollectionChanged()
        }

        // MARK: - View Controller Presentation

        /// Presents a view controller from the topmost visible view
        /// controller.
        ///
        /// Presentation is queued automatically when user interaction
        /// is blocked or an alert controller is already being
        /// presented. Pass `forced` to dismiss any existing alert
        /// controllers and present immediately.
        ///
        /// - Parameters:
        ///   - viewController: The view controller to present.
        ///   - animated: Pass `true` to animate the presentation.
        ///     The default is `true`.
        ///   - embedded: Pass `true` to wrap the view controller in
        ///     a `UINavigationController` before presenting.
        ///   - forced: Pass `true` to dismiss any existing alert
        ///     controllers and present immediately. The default is
        ///     `false`.
        public func present(
            _ viewController: UIViewController,
            animated: Bool = true,
            embedded: Bool = false,
            forced: Bool = false
        ) {
            func forcePresentation() {
                Task { @MainActor in
                    uiApplication.dismissAlertControllers()
                    present(
                        viewController,
                        animated: animated,
                        embedded: embedded
                    )
                }
            }

            guard !forced else {
                return forcePresentation()
            }

            queuePresentation(
                of: viewController,
                animated: animated,
                embedded: embedded
            )
        }

        // MARK: - Other

        /// Forces all windows to adopt the specified user interface
        /// style.
        ///
        /// This override persists until the style is changed again or
        /// the app is relaunched.
        ///
        /// - Parameter style: The interface style to apply. Pass
        ///   `.unspecified` to follow the system setting.
        public func overrideUserInterfaceStyle(_ style: UIUserInterfaceStyle) {
            StatusBar.overrideStyle(style.statusBarStyle)
            uiApplication.windows.forEach { $0.overrideUserInterfaceStyle = style }
        }

        /// Returns a stable integer tag for the given view name.
        ///
        /// Use `semTag(for:)` to assign a view's `tag`, and compare
        /// against `tag` to find that view again:
        ///
        /// ```swift
        /// overlayView.tag = core.ui.semTag(for: "OVERLAY_VIEW")
        ///
        /// let overlayView = subviews.first {
        ///     $0.tag == core.ui.semTag(for: "OVERLAY_VIEW")
        /// }
        /// ```
        ///
        /// Equal names always yield equal tags. The derivation depends on floating-point
        /// formatting, so never persist a tag or compare tags across builds.
        ///
        /// - Important: This method is isolated to the main actor.
        ///
        /// - Parameter viewName: The name that identifies the view.
        ///
        /// - Returns: The integer tag for the given name.
        public func semTag(for viewName: String) -> Int {
            if let semTag = Self.semTags.wrappedValue[viewName] {
                return semTag
            }

            var float: Float = 1

            for (index, character) in viewName.components.enumerated() {
                guard let position = character.alphabeticalPosition else { continue }
                float += float / Float(position * (index + 1))
            }

            let rawString = String(float).removingOccurrences(of: ["."])
            let semTag = Int(rawString) ?? Int(float)
            let collidingName = Self.semTags.wrappedValue.first(where: {
                $0.value == semTag
            })?.key

            assert(
                collidingName == nil,
                "Semantic tag \(semTag) for \"\(viewName)\" collides with \"\(collidingName ?? "")\""
            )

            Self.semTags.wrappedValue[viewName] = semTag
            return semTag
        }

        // MARK: - Auxiliary

        func blockUserInteraction(
            for reason: InteractionBlockingReason,
            dismissSheets: Bool = true
        ) {
            Self.blockingReasons.wrappedValue.insert(reason)
            if dismissSheets {
                Self.sheetDismissingReasons.wrappedValue.insert(reason)
            }

            setRootWindowsUserInteractionEnabled(false)
            startDismissingInteractiveContent()
        }

        func unblockUserInteraction(for reason: InteractionBlockingReason) {
            Self.blockingReasons.wrappedValue.remove(reason)
            Self.sheetDismissingReasons.wrappedValue.remove(reason)
            guard !Self.isBlockingUserInteraction else { return }

            setRootWindowsUserInteractionEnabled(true)
            stopDismissingInteractiveContent()
        }

        private func present(
            _ viewController: UIViewController,
            animated: Bool,
            embedded: Bool
        ) {
            HUD.shared.hide()

            let keyVC = uiApplication.keyViewController
            guard embedded else {
                keyVC?.present(viewController, animated: animated)
                return
            }

            keyVC?.present(UINavigationController(rootViewController: viewController), animated: animated)
        }

        private func queuePresentation(
            of viewController: UIViewController,
            animated: Bool,
            embedded: Bool
        ) {
            Task { @MainActor in
                while Self.isBlockingUserInteraction ||
                    uiApplication.isPresentingAlertController {
                    try? await Task.sleep(for: .milliseconds(Int(Floats.pollIntervalMilliseconds)))
                }

                present(
                    viewController,
                    animated: animated,
                    embedded: embedded
                )
            }
        }
    }
}

private extension CoreKit.UI {
    // MARK: - Interaction Blocking

    func setRootWindowsUserInteractionEnabled(_ isEnabled: Bool) {
        let rootWindowTags = [
            semTag(for: "ROOT_OVERLAY_WINDOW"),
            semTag(for: "ROOT_WINDOW"),
        ]

        uiApplication
            .windows
            .filter { rootWindowTags.contains($0.tag) }
            .forEach { $0.isUserInteractionEnabled = isEnabled }
    }

    // MARK: - Interactive Content Dismissal

    func startDismissingInteractiveContent() {
        guard Self.dismissalTask.wrappedValue == nil else { return }
        Self.dismissalTask.wrappedValue = Task { @MainActor in
            while Self.isBlockingUserInteraction,
                  !Task.isCancelled {
                dismissInteractiveContent()
                try? await Task.sleep(for: .milliseconds(Int(Floats.pollIntervalMilliseconds)))
            }
        }
    }

    func stopDismissingInteractiveContent() {
        Self.dismissalTask.wrappedValue?.cancel()
        Self.dismissalTask.wrappedValue = nil
    }

    func dismissInteractiveContent() {
        Toast.hide()
        uiApplication.dismissAlertControllers()
        if !Self.sheetDismissingReasons.wrappedValue.isEmpty {
            uiApplication.dismissSheets()
        }

        uiApplication.resignFirstResponders()
    }
}

extension UIApplication {
    static var isBlockingUserInteraction: Bool {
        CoreKit.UI.isBlockingUserInteraction
    }
}
