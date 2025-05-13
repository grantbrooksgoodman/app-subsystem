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
    struct UI: Sendable {
        // MARK: - Dependencies

        @Dependency(\.mainQueue) private var mainQueue: DispatchQueue
        @Dependency(\.uiApplication) private var uiApplication: UIApplication

        // MARK: - Properties

        public static let shared = UI()

        // MARK: - Init

        private init() {}

        // MARK: - User Interaction

        func blockUserInteraction() {
            mainQueue.async {
                UIApplication.isBlockingUserInteraction = true

                self.uiApplication
                    .windows?
                    .filter { $0.tag == self.semTag(for: "ROOT_OVERLAY_WINDOW") || $0.tag == self.semTag(for: "ROOT_WINDOW") }
                    .forEach { $0.isUserInteractionEnabled = false }

                self.dismissInteractiveContent()
            }
        }

        func unblockUserInteraction() {
            mainQueue.async {
                guard !CoreKit.HUD.isBlockingUserInteraction,
                      !UIView.isBlockingUserInteraction else { return }

                UIApplication.isBlockingUserInteraction = false

                self.uiApplication
                    .windows?
                    .filter { $0.tag == self.semTag(for: "ROOT_OVERLAY_WINDOW") || $0.tag == self.semTag(for: "ROOT_WINDOW") }
                    .forEach { $0.isUserInteractionEnabled = true }
            }
        }

        // MARK: - View Controller Presentation

        /// - Parameter embedded: Pass `true` to embed the given view controller inside a `UINavigationController`.
        public func present(
            _ viewController: UIViewController,
            animated: Bool = true,
            embedded: Bool = false,
            forced: Bool = false
        ) {
            mainQueue.async {
                func forcePresentation() {
                    uiApplication.dismissAlertControllers()
                    present(viewController, animated: animated, embedded: embedded)
                }

                guard !forced else {
                    guard Thread.isMainThread else { // TODO: Audit this; should now be unnecessary.
                        mainQueue.sync { forcePresentation() }
                        return
                    }

                    forcePresentation()
                    return
                }

                queuePresentation(of: viewController, animated: animated, embedded: embedded)
            }
        }

        // MARK: - Other

        public func overrideUserInterfaceStyle(_ style: UIUserInterfaceStyle) {
            mainQueue.async {
                StatusBar.overrideStyle(style.statusBarStyle)
                guard let windows = uiApplication.windows else { return }
                windows.forEach { $0.overrideUserInterfaceStyle = style }
            }
        }

        /// Generates a semantic, integer-based identifier for a given view name.
        public func semTag(for viewName: String) -> Int {
            var float: Float = 1

            for (index, character) in viewName.components.enumerated() {
                guard let position = character.alphabeticalPosition else { continue }
                float += float / Float(position * (index + 1))
            }

            let rawString = String(float).removingOccurrences(of: ["."])
            guard let integer = Int(rawString) else { return Int(float) }
            return integer
        }

        // MARK: - Auxiliary

        private func dismissInteractiveContent() {
            mainQueue.async {
                guard UIApplication.isBlockingUserInteraction else { return }

                Toast.hide()
                self.uiApplication.dismissAlertControllers()
                self.uiApplication.resignFirstResponders()

                GCD.shared.after(.milliseconds(100)) { self.dismissInteractiveContent() }
            }
        }

        private func present(
            _ viewController: UIViewController,
            animated: Bool,
            embedded: Bool
        ) {
            guard !UIApplication.isBlockingUserInteraction else { return }
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
            guard !uiApplication.isPresentingAlertController else {
                GCD.shared.after(.seconds(1)) { queuePresentation(of: viewController, animated: animated, embedded: embedded) }
                return
            }

            guard Thread.isMainThread else {
                mainQueue.sync { present(viewController, animated: animated, embedded: embedded) }
                return
            }

            present(viewController, animated: animated, embedded: embedded)
        }
    }
}

extension UIApplication {
    fileprivate(set) static var isBlockingUserInteraction = false
}
