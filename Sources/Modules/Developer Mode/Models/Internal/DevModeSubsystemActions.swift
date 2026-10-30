//
//  DevModeSubsystemActions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/* Proprietary */
import AlertKit

extension DevModeAction { // swiftlint:disable:next type_body_length
    enum Subsystem {
        // MARK: - Available Actions Getter

        static var available: [DevModeAction] {
            var availableActions: [DevModeAction] = [
                eraseContentAndSettingsAction,
                overrideLanguageCodeAction,
                toggleBreadcrumbsAction,
                toggleBuildInfoOverlayAction,
                toggleGlassTintingAction,
                toggleTimebombAction,
                viewLoggerSessionRecordAction,
            ].compactMap(\.self)

            if UITheme.allCases.count > 1 {
                availableActions.append(changeThemeAction)
            }

            return availableActions.sorted { $0.title < $1.title }
        }

        // MARK: - Standard Actions

        private static var changeThemeAction: DevModeAction {
            let themeActions: [DevModeAction] = MainActor.assumeIsolated {
                let currentThemeHash = ThemeService.currentTheme.encodedHash
                return UITheme.allCases.map { uiTheme in
                    let isCurrentTheme = uiTheme.encodedHash == currentThemeHash
                    return .init(
                        title: uiTheme.name,
                        iconConfiguration: .init(
                            backgroundColor: isCurrentTheme ? .green : .gray,
                            overlay: .symbol(name: isCurrentTheme ? "checkmark" : "paintpalette.fill")
                        )
                    ) {
                        guard !isCurrentTheme else { return }
                        Task { @MainActor in
                            ThemeService.setTheme(
                                uiTheme,
                                checkStyle: false
                            )
                        }
                    }
                }
            }

            return .init(
                title: "Change Theme",
                iconConfiguration: .init(
                    backgroundColor: .green,
                    overlay: .symbol(name: "eye.fill")
                ),
                destination: themeActions
            )
        }

        private static let eraseContentAndSettingsAction: DevModeAction = {
            @Sendable
            func perform(
                clearCaches: Bool = false,
                resetUserDefaults: Bool = false,
                eraseApplicationSupportDirectory: Bool = false,
                eraseDocumentsDirectory: Bool = false,
                eraseTemporaryDirectory: Bool = false
            ) {
                @Dependency(\.coreKit) var core: CoreKit

                if clearCaches {
                    core.utils.clearCaches()
                }

                if resetUserDefaults {
                    @Dependency(\.userDefaults) var defaults: UserDefaults
                    defaults.reset()
                }

                if eraseApplicationSupportDirectory {
                    do {
                        try core.utils.eraseApplicationSupportDirectory()
                    } catch {
                        Logger.log(
                            error,
                            with: .toast
                        )
                    }
                }

                if eraseDocumentsDirectory {
                    do {
                        try core.utils.eraseDocumentsDirectory()
                    } catch {
                        Logger.log(
                            error,
                            with: .toast
                        )
                    }
                }

                if eraseTemporaryDirectory {
                    do {
                        try core.utils.eraseTemporaryDirectory()
                    } catch {
                        Logger.log(
                            error,
                            with: .toast
                        )
                    }
                }
            }

            @Sendable
            func showSuccess(_ text: String? = nil) {
                @Dependency(\.coreKit.hud) var coreHUD: CoreKit.HUD
                coreHUD.showSuccess(text: text)
            }

            /// Every option confirms through an action sheet whose
            /// sole destructive action carries the option's title.
            @Sendable
            func confirmedAction(
                title: String,
                iconConfiguration: SquareIconView.Configuration,
                isDestructive: Bool = false,
                effect: @escaping @Sendable () -> Void
            ) -> DevModeAction {
                .init(
                    title: title,
                    iconConfiguration: iconConfiguration,
                    isDestructive: isDestructive
                ) {
                    Task {
                        await AKActionSheet(
                            actions: [.init(
                                title,
                                style: .destructive,
                                effect: effect
                            )]
                        ).present(translating: [])
                    }
                }
            }

            let clearCachesAction = confirmedAction(
                title: "Clear Caches",
                iconConfiguration: .init(
                    backgroundColor: .blue,
                    overlay: .symbol(name: "arrow.counterclockwise")
                )
            ) {
                perform(clearCaches: true)
                showSuccess("Cleared Caches")
            }

            let eraseApplicationSupportDirectoryAction = confirmedAction(
                title: "Erase Application Support Directory",
                iconConfiguration: .init(
                    backgroundColor: .orange,
                    overlay: .symbol(name: "folder.fill")
                )
            ) {
                perform(eraseApplicationSupportDirectory: true)
                showSuccess("Erased Application Support Directory")
            }

            let eraseDocumentsDirectoryAction = confirmedAction(
                title: "Erase Documents Directory",
                iconConfiguration: .init(
                    backgroundColor: .indigo,
                    overlay: .symbol(name: "doc.fill")
                )
            ) {
                perform(eraseDocumentsDirectory: true)
                showSuccess("Erased Documents Directory")
            }

            let eraseTemporaryDirectoryAction = confirmedAction(
                title: "Erase Temporary Directory",
                iconConfiguration: .init(
                    backgroundColor: .teal,
                    overlay: .symbol(name: "clock.fill")
                )
            ) {
                perform(eraseTemporaryDirectory: true)
                showSuccess("Erased Temporary Directory")
            }

            let resetUserDefaultsAction = confirmedAction(
                title: "Reset UserDefaults",
                iconConfiguration: .init(
                    backgroundColor: .gray,
                    overlay: .symbol(name: "gearshape.fill")
                )
            ) {
                perform(resetUserDefaults: true)
                showSuccess("Reset UserDefaults")
            }

            let eraseAllContentAndSettingsAction = confirmedAction(
                title: "Erase All Content & Settings",
                iconConfiguration: .init(
                    backgroundColor: .red,
                    overlay: .symbol(name: "trash.fill")
                ),
                isDestructive: true
            ) {
                perform(
                    clearCaches: true,
                    resetUserDefaults: true,
                    eraseApplicationSupportDirectory: true,
                    eraseDocumentsDirectory: true,
                    eraseTemporaryDirectory: true
                )

                showSuccess()
            }

            return .init(
                title: "Erase Content & Settings",
                iconConfiguration: .init(
                    backgroundColor: .red,
                    overlay: .symbol(name: "trash.fill")
                ),
                destination: [
                    clearCachesAction,
                    eraseApplicationSupportDirectoryAction,
                    eraseDocumentsDirectoryAction,
                    eraseTemporaryDirectoryAction,
                    resetUserDefaultsAction,
                    eraseAllContentAndSettingsAction,
                ]
            )
        }()

        private static let viewLoggerSessionRecordAction: DevModeAction = {
            @Sendable
            func viewLoggerSessionRecord() {
                Task { @MainActor in
                    @Dependency(\.quickViewer) var quickViewer: QuickViewer
                    do throws(Exception) {
                        try quickViewer.preview(
                            filesAtPaths: [Logger.sessionRecordFilePath.path()],
                            embedded: true
                        )
                    } catch {
                        Logger.log(
                            error,
                            with: .toast
                        )
                    }
                }
            }

            return .init(
                title: "View Logger Session Record",
                iconConfiguration: .init(
                    backgroundColor: .gray,
                    overlay: .symbol(name: "doc.text.fill")
                ),
                perform: viewLoggerSessionRecord
            )
        }()

        private static var overrideLanguageCodeAction: DevModeAction {
            @Sendable
            func overrideLanguageCode() {
                Task {
                    @Dependency(\.coreKit) var core: CoreKit

                    @Sendable
                    func presentLanguageCodeTextInputAlert() async {
                        @Dependency(\.coreKit) var core: CoreKit
                        let input = await AKTextInputAlert(
                            title: "Override Language Code",
                            message: "Enter the two-letter code of the language to apply:",
                            attributes: .init(
                                capitalizationType: .none,
                                correctionType: .no,
                                placeholderText: "en"
                            )
                        ).present(translating: [])

                        guard let languageCode = input?.lowercasedTrimmingWhitespaceAndNewlines else { return }
                        guard let languageCodes = RuntimeStorage.languageCodeDictionary,
                              languageCodes.keys.contains(languageCode) else {
                            let tryAgainAction: AKAction = .init(
                                "Try Again",
                                style: .preferred
                            ) {
                                Task {
                                    await presentLanguageCodeTextInputAlert()
                                }
                            }

                            return await AKAlert(
                                title: "Override Language Code",
                                message: "The language code entered was invalid. Please try again.",
                                actions: [tryAgainAction, .cancelAction(title: "Cancel")]
                            ).present(translating: [])
                        }

                        core.utils.setLanguageCode(languageCode, override: true)
                        core.hud.showSuccess()
                    }

                    @Sendable
                    func restoreLanguageCode(showSuccess: Bool) {
                        RuntimeStorage.remove(.overriddenLanguageCode)
                        core.utils.restoreDeviceLanguageCode()
                        guard showSuccess else { return }
                        core.hud.showSuccess()
                    }

                    guard RuntimeStorage.retrieve(.overriddenLanguageCode) == nil else {
                        let confirmAction: AKAction = .init("Confirm", style: .preferred) { restoreLanguageCode(showSuccess: true) }
                        let overrideAgainAction: AKAction = .init("Override Again") {
                            restoreLanguageCode(showSuccess: false)
                            overrideLanguageCode()
                        }

                        return await AKAlert(
                            title: "Restore Language Code",
                            message: "The language code will be unlocked and restored to the device's default.",
                            actions: [
                                confirmAction,
                                overrideAgainAction,
                                .cancelAction(title: "Cancel"),
                            ]
                        ).present(translating: [])
                    }

                    let setToRandomLanguageCodeAction: AKAction = .init("Set to Random Language Code") {
                        guard let languageCode = RuntimeStorage.languageCodeDictionary?.keys.randomElement() else { return }
                        core.utils.setLanguageCode(languageCode, override: true)
                        core.hud.showSuccess(
                            text: "Set to \(languageCode.englishLanguageName ?? languageCode.languageName ?? languageCode.uppercased())"
                        )
                    }

                    let specifyLanguageCodeAction: AKAction = .init("Specify Language Code") {
                        Task { await presentLanguageCodeTextInputAlert() }
                    }

                    await AKActionSheet(
                        title: "Override Language Code",
                        actions: [
                            specifyLanguageCodeAction,
                            setToRandomLanguageCodeAction,
                            .cancelAction(title: "Cancel"),
                        ]
                    ).present(translating: [])
                }
            }

            let prefix = RuntimeStorage.retrieve(.overriddenLanguageCode) == nil ? "Override" : "Restore"
            return .init(
                title: "\(prefix) Language Code",
                iconConfiguration: .init(
                    backgroundColor: .blue,
                    overlay: .symbol(name: "globe")
                ),
                perform: overrideLanguageCode
            )
        }

        private static var toggleBreadcrumbsAction: DevModeAction {
            @Sendable
            func toggleBreadcrumbs() {
                Task { @MainActor in
                    @Dependency(\.coreKit.hud) var coreHUD: CoreKit.HUD

                    guard !AppSubsystem.delegates.breadcrumbsCapture.isCapturing else {
                        let confirmed = await AKConfirmationAlert(
                            message: "Stop breadcrumbs capture?",
                            confirmButtonStyle: .destructivePreferred
                        ).present(translating: [])

                        guard confirmed else { return }
                        @Persistent(.breadcrumbsCaptureEnabled) var breadcrumbsCaptureEnabled: Bool?
                        breadcrumbsCaptureEnabled = false

                        do throws(Exception) {
                            try AppSubsystem.delegates.breadcrumbsCapture.stopCapture()
                            coreHUD.showSuccess()
                            DevModeService.refreshMenu()
                        } catch {
                            Logger.log(
                                error,
                                with: .errorAlert
                            )
                        }

                        return
                    }

                    @Sendable
                    func startCapture(_ savesToPhotos: Bool) {
                        Task { @MainActor in
                            @Dependency(\.coreKit.hud) var coreHUD: CoreKit.HUD
                            AppSubsystem.delegates.breadcrumbsCapture.setSavesToPhotos(savesToPhotos)
                            do throws(Exception) {
                                try AppSubsystem.delegates.breadcrumbsCapture.startCapture()
                                coreHUD.showSuccess()
                                DevModeService.refreshMenu()
                            } catch {
                                Logger.log(
                                    error,
                                    with: .errorAlert
                                )
                            }
                        }
                    }

                    let documentsDirectoryOnlyAction: AKAction = .init("Documents Directory Only", style: .preferred) {
                        @Persistent(.breadcrumbsCaptureEnabled) var breadcrumbsCaptureEnabled: Bool?
                        @Persistent(.breadcrumbsCaptureSavesToPhotos) var breadcrumbsCaptureSavesToPhotos: Bool?
                        breadcrumbsCaptureEnabled = true
                        breadcrumbsCaptureSavesToPhotos = false
                        startCapture(false)
                    }

                    let saveToPhotoLibraryAction: AKAction = .init("Save to Photo Library") {
                        @Persistent(.breadcrumbsCaptureEnabled) var breadcrumbsCaptureEnabled: Bool?
                        @Persistent(.breadcrumbsCaptureSavesToPhotos) var breadcrumbsCaptureSavesToPhotos: Bool?
                        breadcrumbsCaptureEnabled = true
                        breadcrumbsCaptureSavesToPhotos = true
                        startCapture(true)
                    }

                    await AKAlert(
                        title: "Start Breadcrumbs Capture", // swiftlint:disable:next line_length
                        message: "Starting breadcrumbs capture will periodically take snapshots of the current view.\n\nSelect the desired file destination to begin.",
                        actions: [
                            saveToPhotoLibraryAction,
                            documentsDirectoryOnlyAction,
                            .cancelAction(title: "Cancel"),
                        ]
                    ).present(translating: [])
                }
            }

            let isCapturing = MainActor.assumeIsolated { AppSubsystem.delegates.breadcrumbsCapture.isCapturing }
            let command = isCapturing ? "Stop" : "Start"
            return .init(
                title: "\(command) Breadcrumbs Capture",
                iconConfiguration: .init(
                    backgroundColor: .orange,
                    overlay: .symbol(name: "camera.fill")
                ),
                isDestructive: command == "Stop",
                perform: toggleBreadcrumbs
            )
        }

        private static var toggleBuildInfoOverlayAction: DevModeAction {
            @Sendable
            func toggleBuildInfoOverlay() {
                switch SharedState(\.isBuildInfoOverlayHidden).wrappedValue {
                case true: BuildInfoOverlay.show()
                case false: BuildInfoOverlay.hide()
                }
            }

            @SharedState(\.isBuildInfoOverlayHidden) var isBuildInfoOverlayHidden
            return .init(
                title: "Hide Build Info Overlay",
                iconConfiguration: .init(
                    backgroundColor: .indigo,
                    overlay: .symbol(name: "info.circle.fill")
                ),
                interaction: .switch(isOn: isBuildInfoOverlayHidden),
                perform: toggleBuildInfoOverlay
            )
        }

        private static var toggleGlassTintingAction: DevModeAction? {
            @Sendable
            func toggleGlassTinting() {
                MainActor.assumeIsolated {
                    @Dependency(\.coreKit) var core: CoreKit

                    @Persistent(.isGlassTintingEnabled) var persistedValue: Bool?
                    core.ui.toggleGlassTinting(on: !(persistedValue == true))

                    core.hud.showSuccess(
                        text: "Glass Tinting \(persistedValue == true ? "Enabled" : "Disabled")"
                    )
                }
            }

            let isFullyV26Compatible = MainActor.assumeIsolated { UIApplication.isFullyV26Compatible }
            let isGlassTintingEnabled = MainActor.assumeIsolated { UIApplication.isGlassTintingEnabled }

            guard isFullyV26Compatible else { return nil }
            return .init(
                title: "Glass Tinting",
                iconConfiguration: .init(
                    backgroundColor: .teal,
                    overlay: .symbol(name: "paintbrush.fill")
                ),
                interaction: .switch(isOn: isGlassTintingEnabled),
                perform: toggleGlassTinting
            )
        }

        private static var toggleTimebombAction: DevModeAction {
            @Sendable
            func toggleTimebomb() {
                @Dependency(\.build) var build: Build
                @Dependency(\.coreKit.hud) var coreHUD: CoreKit.HUD
                build.setIsTimebombActive(!build.isTimebombActive)
                coreHUD.showSuccess(
                    text: "Timebomb \(build.isTimebombActive ? "Enabled" : "Disabled")"
                )
            }

            let isTimebombActive = MainActor.assumeIsolated {
                @Dependency(\.build) var build: Build
                return build.isTimebombActive
            }

            return .init(
                title: "Build Expiry Timebomb",
                iconConfiguration: .init(
                    backgroundColor: .purple,
                    overlay: .symbol(name: "timer")
                ),
                interaction: .switch(isOn: isTimebombActive),
                perform: toggleTimebomb
            )
        }
    }
}
