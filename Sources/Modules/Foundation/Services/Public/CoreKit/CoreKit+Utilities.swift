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
    struct Utilities: Sendable {
        // MARK: - Dependencies

        @Dependency(\.alertKitConfig) private var alertKitConfig: AlertKit.Config
        @Dependency(\.fileManager) private var fileManager: FileManager
        @Dependency(\.uiControl) private var uiControl: UIControl
        @Dependency(\.uiApplication) private var uiApplication: UIApplication

        // MARK: - Properties

        public static let shared = Utilities()

        // MARK: - Computed Properties

        /// The current memory usage of the application in megabytes.
        public var appMemoryFootprint: Int? { getAppMemoryFootprint() }
        public var localizedLanguageCodeDictionary: [String: String]? { getLocalizedLanguageCodeDictionary() }

        // MARK: - Init

        private init() {}

        // MARK: - Methods

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

        /// Returns to the Home screen before terminating the application.
        public func exitGracefully(terminateAfter duration: Duration = .seconds(1)) {
            uiControl
                .sendAction(
                    #selector(NSXPCConnection.suspend),
                    to: uiApplication,
                    for: nil
                )

            GCD.shared.after(duration) { exit(0) }
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

        private func getLocalizedLanguageCodeDictionary() -> [String: String]? {
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
                return .init(error, metadata: [self, #file, #function, #line])
            }

            return nil
        }
    }
}

private enum UIControlDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> UIControl {
        .init()
    }
}

private extension DependencyValues {
    var uiControl: UIControl {
        get { self[UIControlDependency.self] }
        set { self[UIControlDependency.self] = newValue }
    }
}
