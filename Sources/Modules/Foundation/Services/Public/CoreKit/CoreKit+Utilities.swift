//
//  CoreKit+Utilities.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

/* Proprietary */
import AlertKit

public extension CoreKit {
    /// General-purpose utilities for cache management, directory
    /// cleanup, language configuration, and app diagnostics.
    struct Utilities: Sendable {
        // MARK: - Dependencies

        @Dependency(\.fileManager) private var fileManager: FileManager
        @Dependency(\.uiApplication) private var uiApplication: UIApplication
        @Dependency(\.uiControl) private var uiControl: UIControl

        // MARK: - Properties

        static let shared = Utilities()

        // MARK: - Computed Properties

        /// The current memory usage of the app in megabytes.
        public var appMemoryFootprint: Int? {
            getAppMemoryFootprint()
        }

        /// The mapping of supported language codes to language names, localized based on the value of `RuntimeStorage.languageCode`.
        public var localizedLanguageCodeDictionary: [String: String]? {
            localizedLanguageCodeDictionary(for: RuntimeStorage.languageCode)
        }

        // MARK: - Init

        private init() {}

        // MARK: - Methods

        /// Clears the caches for the given domains.
        ///
        /// Pass specific domains to clear only a subset of caches,
        /// or omit the parameter to clear all registered domains.
        ///
        /// - Parameter domains: The cache domains to clear. The
        ///   default is all registered domains.
        public func clearCaches(_ domains: [CacheDomain] = CacheDomain.allCases) {
            domains.forEach { $0.clear() }
        }

        /// Removes all files from the app's Application Support
        /// directory.
        ///
        /// - Returns: An ``Exception`` if the operation fails, or
        ///   `nil` on success.
        @discardableResult
        public func eraseApplicationSupportDirectory() -> Exception? {
            eraseDirectory(at: FileManager.applicationSupportDirectoryURL)
        }

        /// Removes all files from the app's documents
        /// directory.
        ///
        /// - Returns: An ``Exception`` if the operation fails, or
        ///   `nil` on success.
        @discardableResult
        public func eraseDocumentsDirectory() -> Exception? {
            eraseDirectory(at: fileManager.documentsDirectoryURL)
        }

        /// Removes all files from the app's temporary
        /// directory.
        ///
        /// - Returns: An ``Exception`` if the operation fails, or
        ///   `nil` on success.
        @discardableResult
        public func eraseTemporaryDirectory() -> Exception? {
            eraseDirectory(at: fileManager.temporaryDirectory)
        }

        /// Returns to the Home screen before terminating the
        /// app.
        ///
        /// The app suspends immediately, then terminates
        /// after the specified duration.
        ///
        /// - Parameter duration: The delay between suspending and
        ///   terminating. The default is one second.
        @MainActor
        public func exitGracefully(terminateAfter duration: Duration = .seconds(1)) {
            uiControl
                .sendAction(
                    #selector(NSXPCConnection.suspend),
                    to: uiApplication,
                    for: nil
                )

            Task.delayed(by: duration) { @MainActor in
                exit(0)
            }
        }

        /// Returns the mapping of supported language codes to language
        /// names, localized for the given language code.
        ///
        /// Each entry maps a language code (for example, `"fr"`) to
        /// a display name that includes the localized name and, when
        /// different, the endonym in parentheses.
        ///
        /// - Parameter languageCode: The language code to localize
        ///   the display names for.
        ///
        /// - Returns: The localized dictionary, or `nil` if no
        ///   language-code dictionary has been stored in
        ///   ``RuntimeStorage``.
        public func localizedLanguageCodeDictionary(for languageCode: String) -> [String: String]? {
            guard let languageCodeDictionary = RuntimeStorage.languageCodeDictionary else { return nil }
            let locale = Locale(languageCode: .init(languageCode))
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

        /// Restores the active language code to the device's system
        /// language.
        public func restoreDeviceLanguageCode() {
            setLanguageCode(Locale.systemLanguageCode)
        }

        /// Sets the active language code for translation and
        /// localization.
        ///
        /// The new code is stored in ``RuntimeStorage`` and
        /// propagated to the translation service.
        ///
        /// - Parameters:
        ///   - languageCode: The language code to set (for example,
        ///     `"fr"`).
        ///   - override: Pass `true` to persist the code as an
        ///     override that takes precedence over the stored
        ///     language code. The default is `false`.
        public func setLanguageCode(
            _ languageCode: String,
            override: Bool = false
        ) {
            Task { @MainActor in
                @Dependency(\.alertKitConfig) var alertKitConfig: AlertKit.Config
                alertKitConfig.overrideTargetLanguageCode(languageCode)
                RuntimeStorage.store(languageCode, as: .languageCode)

                guard override else { return }
                RuntimeStorage.store(languageCode, as: .overriddenLanguageCode)
            }
        }

        // MARK: - Computed Property Getters

        private func getAppMemoryFootprint() -> Int? {
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

        // MARK: - Auxiliary

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
                return .init(error, metadata: .init(sender: self))
            }

            return nil
        }
    }
}

private enum UIControlDependency: DependencyKey {
    static func resolve(_: DependencyValues) -> UIControl { // swiftformat:disable all
        @MainActorIsolated var uiControl = UIControl()
        return uiControl // swiftformat:enable all
    }
}

private extension DependencyValues {
    var uiControl: UIControl {
        get { self[UIControlDependency.self] }
        set { self[UIControlDependency.self] = newValue }
    }
}
