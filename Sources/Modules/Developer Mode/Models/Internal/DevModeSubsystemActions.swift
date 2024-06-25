//
//  DevModeSubsystemActions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

/* Proprietary */
import AlertKit

extension DevModeAction {
    enum Subsystem {
        // MARK: - Available Actions Getter

        public static var available: [DevModeAction] {
            var availableActions: [DevModeAction] = [
                clearCachesAction,
                toggleBuildInfoOverlayAction,
                overrideLanguageCodeAction,
                resetUserDefaultsAction,
                toggleBreadcrumbsAction,
                toggleTimebombAction,
                viewLoggerSessionRecordAction,
            ]

            if UITheme.allCases.count > 1 {
                availableActions.insert(changeThemeAction, at: 0)
            }

            return availableActions
        }

        // MARK: - Standard Actions

        private static var changeThemeAction: DevModeAction {
            func changeTheme() {
                Task {
                    var actions = [AKAction]()
                    actions = UITheme.allCases.map { uiTheme in
                        .init(
                            uiTheme.name,
                            isEnabled: uiTheme.encodedHash != ThemeService.currentTheme.encodedHash
                        ) {
                            ThemeService.setTheme(uiTheme, checkStyle: false)
                        }
                    }

                    await AKActionSheet(
                        title: "Change Theme",
                        actions: actions
                    ).present(translating: [])
                }
            }

            return .init(title: "Change Theme", perform: changeTheme)
        }

        private static var clearCachesAction: DevModeAction {
            func clearCaches() {
                @Dependency(\.coreKit) var core: CoreKit
                core.utils.clearCaches()
                core.hud.showSuccess(text: "Cleared Caches")
            }

            return .init(title: "Clear Caches", perform: clearCaches)
        }

        private static var overrideLanguageCodeAction: DevModeAction {
            @Sendable
            func overrideLanguageCode() {
                Task {
                    @Dependency(\.coreKit) var core: CoreKit
                    func presentLanguageCodeTextInputAlert() async {
                        let input = await AKTextInputAlert(
                            title: "Override Language Code",
                            message: "Enter the two-letter code of the language to apply:",
                            attributes: .init(
                                capitalizationType: .none,
                                correctionType: .no,
                                placeholderText: "en"
                            )
                        ).present(translating: [])

                        guard let input else { return }
                        guard let languageCodes = RuntimeStorage.languageCodeDictionary,
                              languageCodes.keys.contains(input.lowercasedTrimmingWhitespaceAndNewlines) else {
                            let tryAgainAction: AKAction = .init("Try Again", style: .preferred) {
                                Task { await presentLanguageCodeTextInputAlert() }
                            }

                            return await AKAlert(
                                title: "Override Language Code",
                                message: "The language code entered was invalid. Please try again.",
                                actions: [tryAgainAction, .cancelAction(title: "Cancel")]
                            ).present(translating: [])
                        }

                        core.utils.setLanguageCode(input, override: true)
                        core.hud.showSuccess()
                    }

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

            return .init(title: "Override/Restore Language Code", perform: overrideLanguageCode)
        }

        private static var resetUserDefaultsAction: DevModeAction {
            func resetUserDefaults() {
                @Dependency(\.coreKit.hud) var coreHUD: CoreKit.HUD
                @Dependency(\.userDefaults) var defaults: UserDefaults

                defaults.reset()
                coreHUD.showSuccess(text: "Reset UserDefaults")
            }

            return .init(title: "Reset UserDefaults", perform: resetUserDefaults)
        }

        private static var toggleBreadcrumbsAction: DevModeAction {
            @Dependency(\.breadcrumbs) var breadcrumbs: Breadcrumbs

            func toggleBreadcrumbs() {
                Task {
                    @Dependency(\.coreKit.hud) var coreHUD: CoreKit.HUD

                    @Persistent(.breadcrumbsCaptureEnabled) var breadcrumbsCaptureEnabled: Bool?
                    @Persistent(.breadcrumbsCapturesAllViews) var breadcrumbsCapturesAllViews: Bool?

                    guard !breadcrumbs.isCapturing else {
                        let confirmed = await AKConfirmationAlert(
                            message: "Stop breadcrumbs capture?",
                            confirmButtonStyle: .destructivePreferred
                        ).present(translating: [])

                        guard confirmed else { return }
                        breadcrumbsCaptureEnabled = false

                        if let exception = breadcrumbs.stopCapture() {
                            Logger.log(exception, with: .errorAlert)
                        } else {
                            coreHUD.showSuccess()
                            DevModeService.removeAction(withTitle: "Stop Breadcrumbs Capture")
                            DevModeService.insertAction(toggleBreadcrumbsAction, after: overrideLanguageCodeAction)
                        }

                        return
                    }

                    func startCapture(_ uniqueViewsOnly: Bool) {
                        if let exception = breadcrumbs.startCapture(uniqueViewsOnly: uniqueViewsOnly) {
                            Logger.log(exception, with: .errorAlert)
                        } else {
                            coreHUD.showSuccess()
                            DevModeService.removeAction(withTitle: "Start Breadcrumbs Capture")
                            DevModeService.insertAction(toggleBreadcrumbsAction, after: overrideLanguageCodeAction)
                        }
                    }

                    let allViewsAction: AKAction = .init("All Views") {
                        breadcrumbsCaptureEnabled = true
                        breadcrumbsCapturesAllViews = true
                        startCapture(false)
                    }

                    let uniqueViewsOnlyAction: AKAction = .init("Unique Views Only", style: .preferred) {
                        breadcrumbsCaptureEnabled = true
                        breadcrumbsCapturesAllViews = false
                        startCapture(true)
                    }

                    await AKAlert(
                        title: "Start Breadcrumbs Capture", // swiftlint:disable:next line_length
                        message: "Starting breadcrumbs capture will periodically take snapshots of the current view and save them to the device's photo library.\n\nSelect the capture granularity to begin.",
                        actions: [
                            allViewsAction,
                            uniqueViewsOnlyAction,
                            .cancelAction(title: "Cancel"),
                        ]
                    ).present(translating: [])
                }
            }

            let command = breadcrumbs.isCapturing ? "Stop" : "Start"
            return .init(title: "\(command) Breadcrumbs Capture", isDestructive: command == "Stop", perform: toggleBreadcrumbs)
        }

        private static var toggleBuildInfoOverlayAction: DevModeAction {
            func toggleBuildInfoOverlay() {
                let isHidden = Observables.isBuildInfoOverlayHidden.value
                switch isHidden {
                case true: BuildInfoOverlay.show()
                case false: BuildInfoOverlay.hide()
                }
            }

            return .init(title: "Show/Hide Build Info Overlay", perform: toggleBuildInfoOverlay)
        }

        private static var toggleTimebombAction: DevModeAction {
            @Dependency(\.build) var build: Build

            func toggleTimebomb() {
                @Dependency(\.coreKit.hud) var coreHUD: CoreKit.HUD
                build.setIsTimebombActive(!build.isTimebombActive)
                coreHUD.showSuccess(text: "Timebomb \(build.isTimebombActive ? "Enabled" : "Disabled")")
            }

            return .init(title: "\(build.isTimebombActive ? "Disable" : "Enable") Build Expiry Timebomb", perform: toggleTimebomb)
        }

        private static var viewLoggerSessionRecordAction: DevModeAction {
            func viewLoggerSessionRecord() {
                @Dependency(\.quickViewer) var quickViewer: QuickViewer
                if let exception = quickViewer.preview(
                    filesAtPaths: [Logger.sessionRecordFilePath.path()],
                    embedded: true
                ) {
                    Logger.log(exception, with: .toast())
                }
            }

            return .init(title: "View Logger Session Record", perform: viewLoggerSessionRecord)
        }
    }
}
