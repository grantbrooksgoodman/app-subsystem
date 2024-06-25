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
        @Dependency(\.breadcrumbs) var breadcrumbs: Breadcrumbs
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
        @Persistent(.breadcrumbsCapturesAllViews) var breadcrumbsCapturesAllViews: Bool?
        if _build.milestone == .generalRelease {
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
        public private(set) var loggerDomainSubscription: LoggerDomainSubscriptionDelegate = DefaultLoggerDomainSubscriptionDelegate()
        public private(set) var permanentUserDefaultsKeys: PermanentUserDefaultsKeyDelegate?

        fileprivate static let shared = Delegates()

        /* MARK: Init */

        private init() {}

        /* MARK: Delegate Registration */

        @discardableResult
        public func register(
            appThemeListDelegate: AppThemeListDelegate? = nil,
            buildInfoOverlayDotIndicatorColorDelegate: BuildInfoOverlayDotIndicatorColorDelegate? = nil,
            cacheDomainListDelegate: CacheDomainListDelegate? = nil,
            devModeAppActionDelegate: DevModeAppActionDelegate? = nil,
            exceptionMetadataDelegate: ExceptionMetadataDelegate? = nil,
            localizedStringsDelegate: LocalizedStringsDelegate? = nil,
            loggerDomainSubscriptionDelegate: LoggerDomainSubscriptionDelegate? = nil,
            permanentUserDefaultsKeyDelegate: PermanentUserDefaultsKeyDelegate? = nil
        ) -> Exception? {
            guard appThemeListDelegate != nil ||
                buildInfoOverlayDotIndicatorColorDelegate != nil ||
                cacheDomainListDelegate != nil ||
                devModeAppActionDelegate != nil ||
                exceptionMetadataDelegate != nil ||
                localizedStringsDelegate != nil ||
                loggerDomainSubscriptionDelegate != nil,
                permanentUserDefaultsKeyDelegate != nil else {
                return .init(
                    "No delegates provided in arguments.",
                    metadata: [self, #file, #function, #line]
                )
            }

            if let appThemeListDelegate { appThemeList = appThemeListDelegate }
            if let buildInfoOverlayDotIndicatorColorDelegate { buildInfoOverlayDotIndicatorColor = buildInfoOverlayDotIndicatorColorDelegate }
            if let cacheDomainListDelegate { cacheDomainList = cacheDomainListDelegate }
            if let devModeAppActionDelegate { devModeAppActions = devModeAppActionDelegate }
            if let exceptionMetadataDelegate { exceptionMetadata = exceptionMetadataDelegate }
            if let localizedStringsDelegate { localizedStrings = localizedStringsDelegate }
            if let loggerDomainSubscriptionDelegate { loggerDomainSubscription = loggerDomainSubscriptionDelegate }
            if let permanentUserDefaultsKeyDelegate { permanentUserDefaultsKeys = permanentUserDefaultsKeyDelegate }

            return nil
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

        public func registerLoggerDomainSubscriptionDelegate(_ loggerDomainSubscriptionDelegate: LoggerDomainSubscriptionDelegate) {
            loggerDomainSubscription = loggerDomainSubscriptionDelegate
        }

        public func registerPermanentUserDefaultsKeyDelegate(_ permanentUserDefaultsKeyDelegate: PermanentUserDefaultsKeyDelegate) {
            permanentUserDefaultsKeys = permanentUserDefaultsKeyDelegate
        }
    }
}

// swiftlint:enable identifier_name line_length
