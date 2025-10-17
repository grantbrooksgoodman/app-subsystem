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

    public static let delegates = Delegates.shared

    private(set) static var didInitialize = false

    /* MARK: Initialize */

    // swiftlint:disable:next function_parameter_count
    public static func initialize(
        appStoreBuildNumber: Int,
        buildMilestone: Build.Milestone,
        codeName: String,
        dmyFirstCompileDateString: String,
        finalName: String,
        languageCode: String,
        loggingEnabled: Bool
    ) {
        @Dependency(\.alertKitConfig) var alertKitConfig: AlertKit.Config
        @Dependency(\.coreKit) var core: CoreKit
        @Dependency(\.translatorConfig) var translatorConfig: Translator.Config

        /* MARK: Bundle Properties Setup */

        didInitialize = true

        _build = .init(
            appStoreBuildNumber: appStoreBuildNumber,
            codeName: codeName,
            dmyFirstCompileDateString: dmyFirstCompileDateString,
            finalName: finalName,
            loggingEnabled: loggingEnabled,
            milestone: buildMilestone
        )

        core.utils.setLanguageCode(languageCode)

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
        @Persistent(.breadcrumbsCaptureHistory) var breadcrumbsCaptureHistory: Set<String>?
        @Persistent(.breadcrumbsCaptureSavesToPhotos) var breadcrumbsCaptureSavesToPhotos: Bool?

        if _build.milestone == .generalRelease {
            breadcrumbsCaptureEnabled = false
            breadcrumbsCaptureHistory = nil
            breadcrumbsCaptureSavesToPhotos = nil
        } else if let breadcrumbsCaptureEnabled,
                  let breadcrumbsCaptureSavesToPhotos,
                  breadcrumbsCaptureEnabled {
            delegates.breadcrumbsCapture.setSavesToPhotos(breadcrumbsCaptureSavesToPhotos)
            delegates.breadcrumbsCapture.startCapture()
        }

        /* MARK: Build Info Overlay Setup */

        core.gcd.after(.milliseconds(50)) {
            @Persistent(.hidesBuildInfoOverlay) var hidesBuildInfoOverlay: Bool?
            if let hidesBuildInfoOverlay,
               _build.isDeveloperModeEnabled {
                switch hidesBuildInfoOverlay {
                case true: BuildInfoOverlay.hide()
                case false: BuildInfoOverlay.show()
                }
            } else {
                switch _build.milestone == .generalRelease {
                case true: BuildInfoOverlay.hide()
                case false: BuildInfoOverlay.show()
                }
            }
        }

        /* MARK: Localization & Logging Setup */

        Localization.initialize()

        Logger.setDomainsExcludedFromSessionRecord(delegates.loggerDomainSubscription.domainsExcludedFromSessionRecord)
        Logger.subscribe(to: delegates.loggerDomainSubscription.subscribedDomains)

        /* MARK: Theme Setup */

        @Persistent(.currentThemeID) var currentThemeID: String?
        @Persistent(.pendingThemeID) var pendingThemeID: String?

        if let themeID = pendingThemeID,
           let theme = UITheme.allCases.first(where: { $0.encodedHash == themeID }) {
            ThemeService.setTheme(theme, checkStyle: false)
            pendingThemeID = nil
        } else if let currentThemeID,
                  let theme = UITheme.allCases.first(where: { $0.encodedHash == currentThemeID }) {
            ThemeService.setTheme(theme, checkStyle: false)
        } else {
            ThemeService.setTheme(UITheme.default, checkStyle: false)
        }
    }
}

// MARK: - Delegates

// swiftlint:disable identifier_name line_length
public extension AppSubsystem {
    final class Delegates {
        /* MARK: Properties */

        public private(set) var breadcrumbsCapture: BreadcrumbsCaptureDelegate = Breadcrumbs.shared
        public private(set) var buildInfoOverlayDotIndicatorColor: BuildInfoOverlayDotIndicatorColorDelegate?
        public private(set) var cacheDomainList: CacheDomainListDelegate = DefaultCacheDomainListDelegate()
        public private(set) var devModeAppActions: DevModeAppActionDelegate?
        public private(set) var exceptionMetadata: ExceptionMetadataDelegate?
        public private(set) var forcedUpdateModal: ForcedUpdateModalDelegate?
        public private(set) var localizedStrings: LocalizedStringsDelegate = DefaultLocalizedStringsDelegate()
        public private(set) var loggerDomainSubscription: LoggerDomainSubscriptionDelegate = DefaultLoggerDomainSubscriptionDelegate()
        public private(set) var permanentUserDefaultsKeys: PermanentUserDefaultsKeyDelegate?
        public private(set) var uiThemeList: UIThemeListDelegate = DefaultUIThemeListDelegate()

        fileprivate static let shared = Delegates()

        /* MARK: Init */

        private init() {}

        /* MARK: Delegate Registration */

        @discardableResult
        public func register(
            breadcrumbsCaptureDelegate: BreadcrumbsCaptureDelegate? = nil,
            buildInfoOverlayDotIndicatorColorDelegate: BuildInfoOverlayDotIndicatorColorDelegate? = nil,
            cacheDomainListDelegate: CacheDomainListDelegate? = nil,
            devModeAppActionDelegate: DevModeAppActionDelegate? = nil,
            exceptionMetadataDelegate: ExceptionMetadataDelegate? = nil,
            forcedUpdateModalDelegate: ForcedUpdateModalDelegate? = nil,
            localizedStringsDelegate: LocalizedStringsDelegate? = nil,
            loggerDomainSubscriptionDelegate: LoggerDomainSubscriptionDelegate? = nil,
            permanentUserDefaultsKeyDelegate: PermanentUserDefaultsKeyDelegate? = nil,
            uiThemeListDelegate: UIThemeListDelegate? = nil
        ) -> Exception? {
            guard breadcrumbsCaptureDelegate != nil ||
                buildInfoOverlayDotIndicatorColorDelegate != nil ||
                cacheDomainListDelegate != nil ||
                devModeAppActionDelegate != nil ||
                exceptionMetadataDelegate != nil ||
                forcedUpdateModalDelegate != nil ||
                localizedStringsDelegate != nil ||
                loggerDomainSubscriptionDelegate != nil ||
                permanentUserDefaultsKeyDelegate != nil ||
                uiThemeListDelegate != nil else {
                return .init(
                    "No delegates provided in arguments.",
                    metadata: .init(sender: self)
                )
            }

            if let breadcrumbsCaptureDelegate { breadcrumbsCapture = breadcrumbsCaptureDelegate }
            if let buildInfoOverlayDotIndicatorColorDelegate { buildInfoOverlayDotIndicatorColor = buildInfoOverlayDotIndicatorColorDelegate }
            if let cacheDomainListDelegate { cacheDomainList = cacheDomainListDelegate }
            if let devModeAppActionDelegate { devModeAppActions = devModeAppActionDelegate }
            if let exceptionMetadataDelegate { exceptionMetadata = exceptionMetadataDelegate }
            if let forcedUpdateModalDelegate { forcedUpdateModal = forcedUpdateModalDelegate }
            if let localizedStringsDelegate { localizedStrings = localizedStringsDelegate }
            if let loggerDomainSubscriptionDelegate { loggerDomainSubscription = loggerDomainSubscriptionDelegate }
            if let permanentUserDefaultsKeyDelegate { permanentUserDefaultsKeys = permanentUserDefaultsKeyDelegate }
            if let uiThemeListDelegate { uiThemeList = uiThemeListDelegate }

            return nil
        }

        public func registerBreadcrumbsCaptureDelegate(_ breadcrumbsCaptureDelegate: BreadcrumbsCaptureDelegate) {
            register(breadcrumbsCaptureDelegate: breadcrumbsCapture)
        }

        public func registerBuildInfoOverlayDotIndicatorColorDelegate(_ buildInfoOverlayDotIndicatorColorDelegate: BuildInfoOverlayDotIndicatorColorDelegate) {
            register(buildInfoOverlayDotIndicatorColorDelegate: buildInfoOverlayDotIndicatorColorDelegate)
        }

        public func registerCacheDomainListDelegate(_ cacheDomainListDelegate: CacheDomainListDelegate) {
            register(cacheDomainListDelegate: cacheDomainListDelegate)
        }

        public func registerDevModeAppActionDelegate(_ devModeAppActionDelegate: DevModeAppActionDelegate) {
            register(devModeAppActionDelegate: devModeAppActionDelegate)
        }

        public func registerExceptionMetadataDelegate(_ exceptionMetadataDelegate: ExceptionMetadataDelegate) {
            register(exceptionMetadataDelegate: exceptionMetadataDelegate)
        }

        public func registerForcedUpdateModalDelegate(_ forcedUpdateModalDelegate: ForcedUpdateModalDelegate) {
            register(forcedUpdateModalDelegate: forcedUpdateModalDelegate)
        }

        public func registerLocalizedStringsDelegate(_ localizedStringsDelegate: LocalizedStringsDelegate) {
            register(localizedStringsDelegate: localizedStringsDelegate)
        }

        public func registerLoggerDomainSubscriptionDelegate(_ loggerDomainSubscriptionDelegate: LoggerDomainSubscriptionDelegate) {
            register(loggerDomainSubscriptionDelegate: loggerDomainSubscriptionDelegate)
        }

        public func registerPermanentUserDefaultsKeyDelegate(_ permanentUserDefaultsKeyDelegate: PermanentUserDefaultsKeyDelegate) {
            register(permanentUserDefaultsKeyDelegate: permanentUserDefaultsKeyDelegate)
        }

        public func registerUIThemeListDelegate(_ uiThemeListDelegate: UIThemeListDelegate) {
            register(uiThemeListDelegate: uiThemeListDelegate)
        }
    }
}

// swiftlint:enable identifier_name line_length
