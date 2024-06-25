//
//  AppSubsystem.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/* Proprietary */
import AlertKit
import Translator

// MARK: - AppSubsystem

public enum AppSubsystem {
    /* MARK: Properties */

    public static let bundle = Bundle.shared
    public static let delegates = Delegates.shared

    static var didInitialize = false

    /* MARK: Initialize */

    public static func initialize(
        appStoreReleaseVersion: Int = bundle.appStoreReleaseVersion,
        buildMilestone: Build.Milestone = bundle.buildMilestone,
        codeName: String = bundle.codeName,
        dmyFirstCompileDateString: String = bundle.dmyFirstCompileDateString,
        finalName: String = bundle.finalName,
        languageCode: String = bundle.languageCode,
        loggingEnabled: Bool = bundle.loggingEnabled,
        timebombActive: Bool = bundle.timebombActive
    ) {
        @Dependency(\.alertKitConfig) var alertKitConfig: AlertKit.Config
        @Dependency(\.breadcrumbs) var breadcrumbs: Breadcrumbs
        @Dependency(\.build) var build: Build
        @Dependency(\.coreKit) var core: CoreKit
        @Dependency(\.translatorConfig) var translatorConfig: Translator.Config

        /* MARK: Bundle Properties Setup */

        didInitialize = true

        bundle.setAppStoreReleaseVersion(appStoreReleaseVersion)
        bundle.setBuildMilestone(buildMilestone)
        bundle.setCodeName(codeName)
        bundle.setDMYFirstCompileDateString(dmyFirstCompileDateString)
        bundle.setFinalName(finalName)

        core.utils.setLanguageCode(languageCode)

        bundle.setLoggingEnabled(loggingEnabled)
        bundle.setTimebombActive(timebombActive)

        /* MARK: AlertKit & Translator Setup */

        alertKitConfig.overrideTranslationHUDConfig(.init(appearsAfter: .milliseconds(500), isModal: true))

        alertKitConfig.registerLoggerDelegate(Logger.AlertKitLogger())
        alertKitConfig.registerPresentationDelegate(core)

        ReportDelegate.registerWithDependencies()
        TranslationDelegate.registerWithDependencies()

        LocalTranslationArchiverDelegate.registerWithDependencies()
        translatorConfig.registerLoggerDelegate(Logger.TranslationLogger())

        /* MARK: Breadcrumbs Capture Setup */

        @Persistent(.breadcrumbsCaptureEnabled) var breadcrumbsCaptureEnabled: Bool?
        @Persistent(.breadcrumbsCapturesAllViews) var breadcrumbsCapturesAllViews: Bool?
        if build.milestone == .generalRelease {
            breadcrumbsCaptureEnabled = false
            breadcrumbsCapturesAllViews = nil
        } else if let breadcrumbsCaptureEnabled,
                  let breadcrumbsCapturesAllViews,
                  breadcrumbsCaptureEnabled {
            breadcrumbs.startCapture(uniqueViewsOnly: !breadcrumbsCapturesAllViews)
        }

        /* MARK: Build Info Overlay Setup */

        core.gcd.after(.milliseconds(50)) {
            @Persistent(.hidesBuildInfoOverlay) var hidesBuildInfoOverlay: Bool?
            if let hidesBuildInfoOverlay,
               build.developerModeEnabled {
                switch hidesBuildInfoOverlay {
                case true: BuildInfoOverlay.hide()
                case false: BuildInfoOverlay.show()
                }
            } else {
                switch build.milestone == .generalRelease {
                case true: BuildInfoOverlay.hide()
                case false: BuildInfoOverlay.show()
                }
            }
        }

        /* MARK: Theme Setup */

        @Persistent(.pendingThemeID) var pendingThemeID: String?
        @Persistent(.currentThemeID) var currentThemeID: String?

        if let themeID = pendingThemeID,
           let correspondingCase = AppTheme.allCases.first(where: { $0.theme.encodedHash == themeID }) {
            ThemeService.setTheme(correspondingCase.theme, checkStyle: false)
            pendingThemeID = nil
        } else if let currentThemeID,
                  let correspondingCase = AppTheme.allCases.first(where: { $0.theme.encodedHash == currentThemeID }) {
            ThemeService.setTheme(correspondingCase.theme, checkStyle: false)
        } else {
            ThemeService.setTheme(AppTheme.default.theme, checkStyle: false)
        }
    }
}

// MARK: - Bundle

public extension AppSubsystem {
    final class Bundle {
        /* MARK: Properties */

        // Bool
        public private(set) var loggingEnabled = true
        public private(set) var timebombActive = true

        // String
        public private(set) var codeName = "Template"
        public private(set) var dmyFirstCompileDateString = "29062007"
        public private(set) var finalName = ""
        public private(set) var languageCode = Locale.systemLanguageCode

        // Other
        public private(set) var appStoreReleaseVersion = 0
        public private(set) var buildMilestone: Build.Milestone = .preAlpha

        // swiftlint:disable:next discouraged_direct_init
        fileprivate static let shared = Bundle()

        /* MARK: Init */

        private init() {}

        /* MARK: Setters */

        public func setAppStoreReleaseVersion(_ appStoreReleaseVersion: Int) {
            self.appStoreReleaseVersion = appStoreReleaseVersion
        }

        public func setBuildMilestone(_ buildMilestone: Build.Milestone) {
            self.buildMilestone = buildMilestone
        }

        public func setCodeName(_ codeName: String) {
            self.codeName = codeName
        }

        public func setDMYFirstCompileDateString(_ dmyFirstCompileDateString: String) {
            self.dmyFirstCompileDateString = dmyFirstCompileDateString
        }

        public func setFinalName(_ finalName: String) {
            self.finalName = finalName
        }

        public func setLanguageCode(_ languageCode: String) {
            self.languageCode = languageCode
        }

        public func setLoggingEnabled(_ loggingEnabled: Bool) {
            self.loggingEnabled = loggingEnabled
        }

        public func setTimebombActive(_ timebombActive: Bool) {
            self.timebombActive = timebombActive
        }
    }
}

// MARK: - Delegates

// swiftlint:disable identifier_name line_length
public extension AppSubsystem {
    final class Delegates {
        /* MARK: Properties */

        public private(set) var appThemeList: AppThemeListDelegate = DefaultAppThemeListDelegate()
        public private(set) var buildInfoOverlayDotIndicatorColor: BuildInfoOverlayDotIndicatorColorDelegate = DefaultBuildInfoOverlayDotIndicatorColorDelegate()
        public private(set) var cacheDomainList: CacheDomainListDelegate = DefaultCacheDomainListDelegate()
        public private(set) var devModeAppActions: DevModeAppActionDelegate?
        public private(set) var exceptionMetadata: ExceptionMetadataDelegate?
        public private(set) var localizedStrings: LocalizedStringsDelegate = DefaultLocalizedStringsDelegate()

        fileprivate static let shared = Delegates()

        /* MARK: Init */

        private init() {}

        /* MARK: Delegate Registration */

        public func register(
            appThemeListDelegate: AppThemeListDelegate? = nil,
            buildInfoOverlayDotIndicatorColorDelegate: BuildInfoOverlayDotIndicatorColorDelegate? = nil,
            cacheDomainListDelegate: CacheDomainListDelegate? = nil,
            devModeAppActionDelegate: DevModeAppActionDelegate? = nil,
            exceptionMetadataDelegate: ExceptionMetadataDelegate? = nil,
            localizedStringsDelegate: LocalizedStringsDelegate? = nil
        ) {
            appThemeList = appThemeListDelegate ?? DefaultAppThemeListDelegate()
            buildInfoOverlayDotIndicatorColor = buildInfoOverlayDotIndicatorColorDelegate ?? DefaultBuildInfoOverlayDotIndicatorColorDelegate()
            cacheDomainList = cacheDomainListDelegate ?? DefaultCacheDomainListDelegate()
            devModeAppActions = devModeAppActionDelegate
            exceptionMetadata = exceptionMetadataDelegate
            localizedStrings = localizedStringsDelegate ?? DefaultLocalizedStringsDelegate()
        }

        public func registerAppThemeListDelegate(_ appThemeListDelegate: AppThemeListDelegate) {
            appThemeList = appThemeListDelegate
        }

        public func registerBuildInfoOverlayDotIndicatorColorDelegate(_ buildInfoOverlayDotIndicatorColorDelegate: BuildInfoOverlayDotIndicatorColorDelegate) {
            buildInfoOverlayDotIndicatorColor = buildInfoOverlayDotIndicatorColorDelegate
        }

        public func registerCacheDomainListDelegate(_ cacheDomainListDelegate: CacheDomainListDelegate) {
            cacheDomainList = cacheDomainListDelegate
        }

        public func registerDevModeAppActionDelegate(_ devModeAppActionDelegate: DevModeAppActionDelegate) {
            devModeAppActions = devModeAppActionDelegate
        }

        public func registerExceptionMetadataDelegate(_ exceptionMetadataDelegate: ExceptionMetadataDelegate) {
            exceptionMetadata = exceptionMetadataDelegate
        }

        public func registerLocalizedStringsDelegate(_ localizedStringsDelegate: LocalizedStringsDelegate) {
            localizedStrings = localizedStringsDelegate
        }
    }
}

// swiftlint:enable identifier_name line_length
