//
//  CoreKit.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

/* Proprietary */
import AlertKit

public struct CoreKit {
    // MARK: - Properties

    public let gcd: GCD
    public let hud: HUD
    public let ui: UI
    public let utils: Utilities

    // MARK: - Init

    public init(
        gcd: GCD,
        hud: HUD,
        ui: UI,
        utils: Utilities
    ) {
        self.gcd = gcd
        self.hud = hud
        self.ui = ui
        self.utils = utils
    }

    // MARK: - Core GCD

    public struct GCD {
        /* MARK: Dependencies */

        @Dependency(\.mainQueue) private var mainQueue: DispatchQueue

        /* MARK: Methods */

        public func after(_ duration: Duration, do effect: @escaping () -> Void) {
            mainQueue.asyncAfter(deadline: .now() + .milliseconds(.init(duration.milliseconds))) {
                effect()
            }
        }
    }

    // MARK: - Core HUD

    public struct HUD {
        /* MARK: Types */

        public enum HUDImage {
            case success
            case exclamation
        }

        /* MARK: Dependencies */

        @Dependency(\.mainQueue) private var mainQueue: DispatchQueue
        @Dependency(\.uiApplication) private var uiApplication: UIApplication

        /* MARK: Properties */

        private var windows: [UIWindow]? {
            let ui: UI = .init()
            return uiApplication
                .windows?
                .filter { $0.tag == ui.semTag(for: "ROOT_OVERLAY_WINDOW") || $0.tag == ui.semTag(for: "ROOT_WINDOW") }
        }

        /* MARK: Methods */

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
                mainQueue.async { ProgressHUD.show(resolvedText, icon: animatedIcon, interaction: true) }
                return
            }

            mainQueue.async { ProgressHUD.show(resolvedText, icon: alertIcon, interaction: true) }
        }

        public func hide(after delay: Duration? = nil) {
            mainQueue.async {
                let gcd: GCD = .init()

                func hideHUD() {
                    windows?.forEach { $0.isUserInteractionEnabled = true }
                    ProgressHUD.dismiss()
                    gcd.after(.milliseconds(250)) { ProgressHUD.remove() }
                }

                guard let delay else { return hideHUD() }
                gcd.after(delay) { hideHUD() }
            }
        }

        public func showProgress(
            text: String? = nil,
            after delay: Duration? = nil,
            isModal: Bool = false
        ) {
            mainQueue.async {
                func showHUD() {
                    ProgressHUD.show(text)
                    guard isModal else { return }
                    windows?.forEach { $0.isUserInteractionEnabled = false }
                }

                guard let delay else { return showHUD() }
                GCD().after(delay) { showHUD() }
            }
        }

        public func showSuccess(text: String? = nil) {
            mainQueue.async {
                ProgressHUD.showSucceed(text)
            }
        }
    }

    // MARK: - Core UI

    public struct UI {
        /* MARK: Dependencies */

        @Dependency(\.mainQueue) private var mainQueue: DispatchQueue
        @Dependency(\.uiApplication) private var uiApplication: UIApplication

        /* MARK: View Controller Presentation */

        // Public

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

        public func overrideUserInterfaceStyle(_ style: UIUserInterfaceStyle) {
            mainQueue.async {
                StatusBarStyle.override(style.statusBarStyle)
                guard let windows = uiApplication.windows else { return }
                windows.forEach { $0.overrideUserInterfaceStyle = style }
            }
        }

        // Private

        private func present(
            _ viewController: UIViewController,
            animated: Bool,
            embedded: Bool
        ) {
            HUD().hide()

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
                GCD().after(.seconds(1)) { queuePresentation(of: viewController, animated: animated, embedded: embedded) }
                return
            }

            guard Thread.isMainThread else {
                mainQueue.sync { present(viewController, animated: animated, embedded: embedded) }
                return
            }

            present(viewController, animated: animated, embedded: embedded)
        }

        /* MARK: View Tagging */

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
    }

    // MARK: - Core Utilities

    public struct Utilities {
        /* MARK: Dependencies */

        @Dependency(\.alertKitConfig) private var alertKitConfig: AlertKit.Config
        @Dependency(\.fileManager) private var fileManager: FileManager

        /* MARK: Properties */

        /// The current memory usage of the application in megabytes.
        public var appMemoryFootprint: Int? {
            let taskVmInfoCount = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
            guard let minAddressOffset = MemoryLayout.offset(of: \task_vm_info_data_t.min_address) else { return nil }

            let taskVmInfoRev1Count = mach_msg_type_number_t(minAddressOffset / MemoryLayout<integer_t>.size)
            var taskVmInfo = task_vm_info_data_t()
            var infoCount = taskVmInfoCount
            let kernelReturnCode = withUnsafeMutablePointer(to: &taskVmInfo) { taskVmInfoPointer in
                taskVmInfoPointer.withMemoryRebound(to: integer_t.self, capacity: Int(infoCount)) { intPointer in
                    task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), intPointer, &infoCount)
                }
            }

            guard infoCount >= taskVmInfoRev1Count,
                  kernelReturnCode == KERN_SUCCESS else { return nil }

            return Int(UInt64(Float(taskVmInfo.phys_footprint)) / 1024 / 1024)
        }

        public var localizedLanguageCodeDictionary: [String: String]? {
            guard let languageCodeDictionary = RuntimeStorage.languageCodeDictionary else { return nil }

            let locale = Locale(languageCode: .init(RuntimeStorage.languageCode))

            return languageCodeDictionary.reduce(into: [String: String]()) { partialResult, keyPair in
                let code = keyPair.key
                let name = keyPair.value

                if let localizedName = locale.localizedString(forLanguageCode: code) {
                    let components = name.components(separatedBy: "(")
                    if components.count == 2 {
                        let endonym = components[1]
                        let suffix = localizedName.lowercased() == endonym.lowercased().dropSuffix() ? "" : "(\(endonym)"
                        partialResult[code] = "\(localizedName.firstUppercase) \(suffix)".trimmingBorderedWhitespace
                    } else {
                        let suffix = localizedName.lowercased() == name.lowercased() ? "" : "(\(name))"
                        partialResult[code] = "\(localizedName.firstUppercase) \(suffix)".trimmingBorderedWhitespace
                    }
                } else {
                    partialResult[code] = name.trimmingBorderedWhitespace
                }
            }
        }

        /* MARK: Methods */

        public func clearCaches(_ domains: [CacheDomain] = CacheDomain.allCases) {
            domains.forEach { $0.clear() }
        }

        @discardableResult
        public func eraseDocumentsDirectory() -> Exception? {
            eraseDirectory(at: fileManager.documentsDirectoryURL)
        }

        @discardableResult
        public func eraseTemporaryDirectory() -> Exception? {
            eraseDirectory(at: fileManager.temporaryDirectory)
        }

        public func restoreDeviceLanguageCode() {
            setLanguageCode(Locale.systemLanguageCode)
        }

        public func setLanguageCode(_ languageCode: String, override: Bool = false) {
            alertKitConfig.overrideTargetLanguageCode(languageCode)
            RuntimeStorage.store(languageCode, as: .languageCode)

            guard override else { return }
            RuntimeStorage.store(languageCode, as: .overriddenLanguageCode)
        }

        private func eraseDirectory(at path: URL) -> Exception? {
            do {
                let filePaths = try fileManager.contentsOfDirectory(
                    at: path,
                    includingPropertiesForKeys: nil
                )

                for path in filePaths {
                    try fileManager.removeItem(at: path)
                }
            } catch {
                return .init(error, metadata: [self, #file, #function, #line])
            }

            return nil
        }
    }
}
