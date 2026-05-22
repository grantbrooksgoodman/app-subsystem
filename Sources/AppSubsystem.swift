//
//  AppSubsystem.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

/* Proprietary */
import AlertKit
import Translator

// MARK: - AppSubsystem

/// A foundational framework for building iOS apps with
/// structured state management, dependency injection, and reactive
/// observation.
///
/// AppSubsystem provides the core architecture that apps build on.
/// It manages the build lifecycle, theming, logging, localization,
/// and developer tools so that app code can focus on features rather
/// than infrastructure.
///
/// ## Overview
///
/// The framework is organized around a few central ideas:
///
/// AppSubsystem is organized around several key concepts:
///
/// - **Reducers and view models.** Each screen defines a ``Reducer`` that describes how state changes in response to actions. A ``ViewModel`` connects that reducer to SwiftUI, publishing state and accepting actions through bindings. Data flows in one direction: from actions, through the reducer, into state, and out to the view.
///
/// - **Dependency injection.** Services and configuration are provided through the ``@Dependency`` property wrapper rather than singletons or initializer parameters. Dependencies are resolved at the call site and can be overridden for testing or previews.
///
/// - **Reactive observation.** Shared values that cross feature boundaries are expressed as ``Observable`` instances. Views subscribe through the ``Observer`` protocol, which dispatches changes to the appropriate reducer on the main actor.
///
/// - **Theming.** Appearance is driven by a ``UITheme`` value that can be swapped at runtime. Views that adopt the theming system update automatically when the active theme changes.
///
/// - **Localization.** Multi-language support is built in through property-list-based string tables and an integrated translation pipeline powered by [Translator](https://github.com/grantbrooksgoodman/translator).
///
/// - **Navigation.** A coordinator-based navigation system manages stack, sheet, and modal presentation through a single published state value. SwiftUI views bind directly to the coordinator and respond to navigation changes automatically.
///
/// - **Developer tools.** Pre-release builds include a build-info overlay, breadcrumb capture, logging, and a Developer Mode action menu – all of which are disabled or hidden in general-release builds automatically.
///
/// ## Bootstrapping
///
/// Call ``initialize(appStoreBuildNumber:buildMilestone:codeName:finalName:languageCode:loggingEnabled:)``
/// once at app launch, typically inside your `App` initializer or
/// `application(_:didFinishLaunchingWithOptions:)`:
///
/// ```swift
/// @main
/// struct MyApp: App {
///    init() {
///        AppSubsystem.initialize(
///            appStoreBuildNumber: 0,
///            buildMilestone: .preAlpha,
///            codeName: "Alpine",
///            finalName: "My App",
///            languageCode: Locale.systemLanguageCode,
///            loggingEnabled: true
///        )
///    }
///
///    var body: some Scene { ... }
/// }
/// ```
///
/// This single call configures the build environment, logging, localization,
/// theming, and all internal subsystem services. It may only be called once
/// per application lifecycle.
///
/// ## Customization via Delegates
///
/// Default behavior can be replaced or extended by registering delegates on
/// ``delegates`` before or after initialization. Delegates with sensible
/// defaults (theme list, cache domains, logger subscriptions) are
/// provided out of the box; optional delegates (exception metadata, forced
/// update modals, Developer Mode actions) can be registered as needed:
///
/// ```swift
/// AppSubsystem.delegates.register(
///    exceptionMetadataDelegate: myExceptionDelegate,
///    uiThemeListDelegate: myThemeListDelegate
/// )
/// ```
///
public enum AppSubsystem {
    /* MARK: Properties */

    /// A registry of app-level delegates that customize the
    /// subsystem's behavior.
    public static let delegates = Delegates.shared

    private static let _didInitialize = LockIsolated(false)

    /* MARK: Computed Properties */

    static var didInitialize: Bool {
        get { _didInitialize.wrappedValue }
        set { _didInitialize.wrappedValue = newValue }
    }

    /* MARK: Initialize */

    /// Configures the subsystem and prepares all internal services for use.
    ///
    /// Call this method once at app launch. It sets up the build
    /// environment, registers framework delegates, configures logging and
    /// localization, and restores the active theme from persistent storage.
    ///
    /// - Parameters:
    ///   - appStoreBuildNumber: The build number submitted to the App Store.
    ///   - buildMilestone: The current stage of the release cycle.
    ///   - codeName: An internal code name for this release.
    ///   - finalName: The user-facing application name.
    ///   - languageCode: The default language code for localization.
    ///   - loggingEnabled: A Boolean value that determines whether the
    ///     logger produces output.
    ///
    /// - Important: This method must be called on the main actor.
    ///
    /// - Warning: Calling this method more than once per application
    ///   lifecycle results in a fatal error.
    @MainActor // swiftlint:disable:next function_parameter_count
    public static func initialize(
        appStoreBuildNumber: Int,
        buildMilestone: Build.Milestone,
        codeName: String,
        finalName: String,
        languageCode: String,
        loggingEnabled: Bool
    ) {
        @Dependency(\.alertKitConfig) var alertKitConfig: AlertKit.Config
        @Dependency(\.coreKit) var core: CoreKit
        @Dependency(\.translationService) var translationService: TranslationService
        @Dependency(\.translatorConfig) var translatorConfig: Translator.Config

        /* MARK: Bundle Properties Setup */

        guard !didInitialize else {
            fatalError(
                "AppSubsystem.initialize(...) may only be called once per application lifecycle"
            )
        }

        _build = .init(
            appStoreBuildNumber: appStoreBuildNumber,
            codeName: codeName,
            finalName: finalName,
            loggingEnabled: loggingEnabled,
            milestone: buildMilestone
        )

        didInitialize = true
        core.utils.setLanguageCode(languageCode)

        /* MARK: AlertKit & Translator Setup */

        alertKitConfig.overrideTranslationHUDConfig(.init(appearsAfter: .milliseconds(500), isModal: true))

        alertKitConfig.registerLoggerDelegate(Logger.AlertKitLogger())
        alertKitConfig.registerPresentationDelegate(core)

        InspectionDelegate.registerWithDependencies()
        ReportDelegate.registerWithDependencies()
        TranslationDelegate.registerWithDependencies()

        LocalTranslationArchiverDelegate.registerWithDependencies()
        translatorConfig.registerLoggerDelegate(Logger.TranslationLogger())

        translationService.prewarm()

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
            try? delegates.breadcrumbsCapture.startCapture()
        }

        /* MARK: Build Info Overlay Setup */

        Task.delayed(by: .milliseconds(50)) { @MainActor in
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

        /* MARK: Glass Tinting Setup */

        @Persistent(.isGlassTintingEnabled) var isGlassTintingEnabled: Bool?

        if !UIApplication.isFullyV26Compatible {
            isGlassTintingEnabled = false
        } else if !_build.isDeveloperModeEnabled {
            isGlassTintingEnabled = true
        }

        isGlassTintingEnabled = isGlassTintingEnabled ?? true

        /* MARK: Localization & Logging Setup */

        LocalizedStringResolver.initialize()

        Logger.setDomainsExcludedFromSessionRecord(delegates.loggerDomainSubscription.domainsExcludedFromSessionRecord)
        Logger.subscribe(to: delegates.loggerDomainSubscription.subscribedDomains)

        /* MARK: Theme Setup */

        @Persistent(.currentThemeID) var currentThemeID: String?
        @Persistent(.pendingThemeID) var pendingThemeID: String?

        if let themeID = pendingThemeID ?? currentThemeID,
           let theme = UITheme.allCases.first(where: {
               $0.encodedHash == themeID
           }) {
            ThemeService.setTheme(
                theme,
                checkStyle: false
            )
        } else {
            ThemeService.setTheme(
                UITheme.default,
                checkStyle: false
            )
        }
    }
}

// MARK: - Delegates

// swiftlint:disable identifier_name
public extension AppSubsystem {
    /// A registry of app-level delegates that customize the
    /// subsystem's behavior.
    ///
    /// ## Overview
    ///
    /// The ``Delegates`` class manages the delegates that the
    /// subsystem consults for theming, logging, localization,
    /// developer tools, and other configurable behaviors. Access
    /// the shared instance through ``AppSubsystem/delegates``.
    ///
    /// Delegates fall into two categories:
    ///
    /// - **Defaulted.** Properties such as ``uiThemeList`` are populated with working
    ///   implementations automatically. Replace them only when you
    ///   need to customize the default behavior.
    ///
    /// - **Optional.** Properties such as ``exceptionMetadata``
    ///   and ``forcedUpdateModal`` start as `nil` and enable
    ///   opt-in functionality. Set them when your app requires the
    ///   corresponding feature.
    ///
    /// Register delegates individually or in a single batch call:
    ///
    /// ```swift
    /// // Batch registration.
    /// AppSubsystem.delegates.register(
    ///     exceptionMetadataDelegate: myExceptionDelegate,
    ///     uiThemeListDelegate: myThemeListDelegate
    /// )
    ///
    /// // Single registration.
    /// AppSubsystem.delegates.registerExceptionMetadataDelegate(myExceptionDelegate)
    /// ```
    ///
    /// Delegates may be registered before or after calling
    /// ``AppSubsystem/initialize(appStoreBuildNumber:buildMilestone:codeName:finalName:languageCode:loggingEnabled:)``.
    /// Delegates that the subsystem reads during initialization –
    /// such as ``loggerDomainSubscription`` – should be registered
    /// beforehand so their values are available at setup time.
    ///
    /// - Note: All delegate access is safe to perform from any
    ///   thread.
    final class Delegates: @unchecked Sendable {
        /* MARK: Properties */

        /// The delegate that manages periodic screenshot capture
        /// for diagnostic purposes.
        ///
        /// The default implementation captures snapshots of the
        /// current view hierarchy at regular intervals and writes
        /// them to the app's documents directory. The subsystem
        /// disables capture automatically in general-release
        /// builds.
        ///
        /// - Important: Register a replacement before calling
        ///   ``AppSubsystem/initialize(appStoreBuildNumber:buildMilestone:codeName:finalName:languageCode:loggingEnabled:)``.
        ///   The subsystem reads this delegate's values during
        ///   setup and does not re-read them afterward.
        ///
        /// - SeeAlso: ``BreadcrumbsCaptureDelegate``
        @LockIsolated public private(set) var breadcrumbsCapture: BreadcrumbsCaptureDelegate = Breadcrumbs.shared

        /// The delegate that supplies the list of cache domains
        /// known to the app.
        ///
        /// The default value is a
        /// ``DefaultCacheDomainListDelegate`` instance, which
        /// returns only the subsystem's built-in domains. Replace
        /// this delegate to include your app's cache domains in
        /// bulk operations such as clearing all caches.
        ///
        /// - SeeAlso: ``CacheDomainListDelegate``
        @LockIsolated public private(set) var cacheDomainList: CacheDomainListDelegate = DefaultCacheDomainListDelegate()

        /// The delegate that specifies which logger domains are
        /// active at launch.
        ///
        /// The default value is a
        /// ``DefaultLoggerDomainSubscriptionDelegate`` instance,
        /// which subscribes to all built-in subsystem domains and
        /// excludes none from the session record.
        ///
        /// - Important: Register a replacement before calling
        ///   ``AppSubsystem/initialize(appStoreBuildNumber:buildMilestone:codeName:finalName:languageCode:loggingEnabled:)``.
        ///   The subsystem reads this delegate's values during
        ///   setup and does not re-read them afterward.
        ///
        /// - SeeAlso: ``LoggerDomainSubscriptionDelegate``
        @LockIsolated public private(set) var loggerDomainSubscription: LoggerDomainSubscriptionDelegate = DefaultLoggerDomainSubscriptionDelegate()

        /// The delegate that provides the list of available UI
        /// themes.
        ///
        /// The default value is a ``DefaultUIThemeListDelegate``
        /// instance, which includes only the subsystem's built-in
        /// themes. Replace this delegate to register custom themes
        /// alongside the built-in set.
        ///
        /// - Important: Register a replacement before calling
        ///   ``AppSubsystem/initialize(appStoreBuildNumber:buildMilestone:codeName:finalName:languageCode:loggingEnabled:)``.
        ///   The subsystem reads this delegate's values during
        ///   setup and does not re-read them afterward.
        ///
        /// - SeeAlso: ``UIThemeListDelegate``
        @LockIsolated public private(set) var uiThemeList: UIThemeListDelegate = DefaultUIThemeListDelegate()

        fileprivate static let shared = Delegates()

        private let _buildInfoOverlayDotIndicatorColor = LockIsolated<BuildInfoOverlayDotIndicatorColorDelegate?>(nil)
        private let _devModeAppActions = LockIsolated<DevModeAppActionDelegate?>(nil)
        private let _exceptionMetadata = LockIsolated<ExceptionMetadataDelegate?>(nil)
        private let _forcedUpdateModal = LockIsolated<ForcedUpdateModalDelegate?>(nil)
        private let _permanentPersistentStorageKeys = LockIsolated<PermanentPersistentStorageKeyDelegate?>(nil)

        /* MARK: Computed Properties */

        /// The delegate that provides a custom color for the
        /// Developer Mode indicator dot in the build info overlay.
        ///
        /// When this property is `nil`, the indicator dot uses the
        /// default color.
        ///
        /// - SeeAlso: ``BuildInfoOverlayDotIndicatorColorDelegate``
        public var buildInfoOverlayDotIndicatorColor: BuildInfoOverlayDotIndicatorColorDelegate? {
            get { _buildInfoOverlayDotIndicatorColor.wrappedValue }
            set { _buildInfoOverlayDotIndicatorColor.wrappedValue = newValue }
        }

        /// The delegate that supplies app-specific actions to the
        /// Developer Mode menu.
        ///
        /// When this property is `nil`, the Developer Mode menu
        /// displays only the subsystem's built-in actions.
        ///
        /// - SeeAlso: ``DevModeAppActionDelegate``
        public var devModeAppActions: DevModeAppActionDelegate? {
            get { _devModeAppActions.wrappedValue }
            set { _devModeAppActions.wrappedValue = newValue }
        }

        /// The delegate that provides app-specific metadata for
        /// exception handling.
        ///
        /// Use this delegate to control which exceptions are
        /// reportable and to supply user-facing descriptions for
        /// known error conditions.
        ///
        /// When this property is `nil`, all exceptions are
        /// reportable and no user-facing descriptors are available.
        ///
        /// - SeeAlso: ``ExceptionMetadataDelegate``
        public var exceptionMetadata: ExceptionMetadataDelegate? {
            get { _exceptionMetadata.wrappedValue }
            set { _exceptionMetadata.wrappedValue = newValue }
        }

        /// The delegate that drives the presentation of a
        /// full-screen modal requiring the user to update the app.
        ///
        /// When this property is `nil`, forced-update
        /// functionality is disabled.
        ///
        /// - SeeAlso: ``ForcedUpdateModalDelegate``
        public var forcedUpdateModal: ForcedUpdateModalDelegate? {
            get { _forcedUpdateModal.wrappedValue }
            set { _forcedUpdateModal.wrappedValue = newValue }
        }

        /// The delegate that declares which `UserDefaults` keys
        /// should survive a reset.
        ///
        /// When this property is `nil`, only the subsystem's own
        /// keys are preserved during a `UserDefaults` reset.
        ///
        /// - SeeAlso: ``PermanentPersistentStorageKeyDelegate``
        public var permanentPersistentStorageKeys: PermanentPersistentStorageKeyDelegate? {
            get { _permanentPersistentStorageKeys.wrappedValue }
            set { _permanentPersistentStorageKeys.wrappedValue = newValue }
        }

        /* MARK: Init */

        private init() {}

        /* MARK: Delegate Registration */

        /// Registers one or more delegates in a single call.
        ///
        /// Each parameter defaults to `nil`. Pass only the
        /// delegates you want to register; existing delegates for
        /// omitted parameters remain unchanged:
        ///
        /// ```swift
        /// AppSubsystem.delegates.register(
        ///     cacheDomainListDelegate: myCacheDomains,
        ///     uiThemeListDelegate: myThemes
        /// )
        /// ```
        ///
        /// To register a single delegate, you can also use the
        /// corresponding type-specific method – for example,
        /// ``registerCacheDomainListDelegate(_:)``.
        ///
        /// - Parameters:
        ///   - breadcrumbsCaptureDelegate: A delegate that manages
        ///     periodic screenshot capture.
        ///   - buildInfoOverlayDotIndicatorColorDelegate: A
        ///     delegate that provides the indicator dot color.
        ///   - cacheDomainListDelegate: A delegate that supplies
        ///     app-specific cache domains.
        ///   - devModeAppActionDelegate: A delegate that supplies
        ///     Developer Mode actions.
        ///   - exceptionMetadataDelegate: A delegate that provides
        ///     exception metadata.
        ///   - forcedUpdateModalDelegate: A delegate that drives
        ///     forced-update presentation.
        ///   - loggerDomainSubscriptionDelegate: A delegate that
        ///     specifies subscribed logger domains.
        ///   - permanentPersistentStorageKeyDelegate: A delegate that
        ///     declares permanent `UserDefaults` keys.
        ///   - uiThemeListDelegate: A delegate that provides the
        ///     theme list.
        ///
        /// - Important: At least one non-`nil` argument must be
        ///   provided. Passing all `nil` values triggers an
        ///   assertion failure in debug builds.
        public func register(
            breadcrumbsCaptureDelegate: BreadcrumbsCaptureDelegate? = nil,
            buildInfoOverlayDotIndicatorColorDelegate: BuildInfoOverlayDotIndicatorColorDelegate? = nil,
            cacheDomainListDelegate: CacheDomainListDelegate? = nil,
            devModeAppActionDelegate: DevModeAppActionDelegate? = nil,
            exceptionMetadataDelegate: ExceptionMetadataDelegate? = nil,
            forcedUpdateModalDelegate: ForcedUpdateModalDelegate? = nil,
            loggerDomainSubscriptionDelegate: LoggerDomainSubscriptionDelegate? = nil,
            permanentPersistentStorageKeyDelegate: PermanentPersistentStorageKeyDelegate? = nil,
            uiThemeListDelegate: UIThemeListDelegate? = nil
        ) {
            guard breadcrumbsCaptureDelegate != nil ||
                buildInfoOverlayDotIndicatorColorDelegate != nil ||
                cacheDomainListDelegate != nil ||
                devModeAppActionDelegate != nil ||
                exceptionMetadataDelegate != nil ||
                forcedUpdateModalDelegate != nil ||
                loggerDomainSubscriptionDelegate != nil ||
                permanentPersistentStorageKeyDelegate != nil ||
                uiThemeListDelegate != nil else {
                assertionFailure("No delegates provided in arguments.")
                return
            }

            if let breadcrumbsCaptureDelegate { breadcrumbsCapture = breadcrumbsCaptureDelegate }
            if let buildInfoOverlayDotIndicatorColorDelegate { buildInfoOverlayDotIndicatorColor = buildInfoOverlayDotIndicatorColorDelegate }
            if let cacheDomainListDelegate { cacheDomainList = cacheDomainListDelegate }
            if let devModeAppActionDelegate { devModeAppActions = devModeAppActionDelegate }
            if let exceptionMetadataDelegate { exceptionMetadata = exceptionMetadataDelegate }
            if let forcedUpdateModalDelegate { forcedUpdateModal = forcedUpdateModalDelegate }
            if let loggerDomainSubscriptionDelegate { loggerDomainSubscription = loggerDomainSubscriptionDelegate }
            if let permanentPersistentStorageKeyDelegate { permanentPersistentStorageKeys = permanentPersistentStorageKeyDelegate }
            if let uiThemeListDelegate { uiThemeList = uiThemeListDelegate }
        }

        /// Registers the specified breadcrumbs capture delegate.
        ///
        /// - Parameter breadcrumbsCaptureDelegate: The delegate to
        ///   register.
        ///
        /// - SeeAlso: ``BreadcrumbsCaptureDelegate``
        public func registerBreadcrumbsCaptureDelegate(
            _ breadcrumbsCaptureDelegate: BreadcrumbsCaptureDelegate
        ) {
            register(breadcrumbsCaptureDelegate: breadcrumbsCaptureDelegate)
        }

        /// Registers the specified build info overlay dot indicator
        /// color delegate.
        ///
        /// - Parameter buildInfoOverlayDotIndicatorColorDelegate:
        ///   The delegate to register.
        ///
        /// - SeeAlso: ``BuildInfoOverlayDotIndicatorColorDelegate``
        public func registerBuildInfoOverlayDotIndicatorColorDelegate(
            _ buildInfoOverlayDotIndicatorColorDelegate: BuildInfoOverlayDotIndicatorColorDelegate
        ) {
            register(buildInfoOverlayDotIndicatorColorDelegate: buildInfoOverlayDotIndicatorColorDelegate)
        }

        /// Registers the specified cache domain list delegate.
        ///
        /// - Parameter cacheDomainListDelegate: The delegate to
        ///   register.
        ///
        /// - SeeAlso: ``CacheDomainListDelegate``
        public func registerCacheDomainListDelegate(
            _ cacheDomainListDelegate: CacheDomainListDelegate
        ) {
            register(cacheDomainListDelegate: cacheDomainListDelegate)
        }

        /// Registers the specified Developer Mode app action delegate.
        ///
        /// - Parameter devModeAppActionDelegate: The delegate to
        ///   register.
        ///
        /// - SeeAlso: ``DevModeAppActionDelegate``
        public func registerDevModeAppActionDelegate(
            _ devModeAppActionDelegate: DevModeAppActionDelegate
        ) {
            register(devModeAppActionDelegate: devModeAppActionDelegate)
        }

        /// Registers the specified exception metadata delegate.
        ///
        /// - Parameter exceptionMetadataDelegate: The delegate to
        ///   register.
        ///
        /// - SeeAlso: ``ExceptionMetadataDelegate``
        public func registerExceptionMetadataDelegate(
            _ exceptionMetadataDelegate: ExceptionMetadataDelegate
        ) {
            register(exceptionMetadataDelegate: exceptionMetadataDelegate)
        }

        /// Registers the specified forced-update modal delegate.
        ///
        /// - Parameter forcedUpdateModalDelegate: The delegate to
        ///   register.
        ///
        /// - SeeAlso: ``ForcedUpdateModalDelegate``
        public func registerForcedUpdateModalDelegate(
            _ forcedUpdateModalDelegate: ForcedUpdateModalDelegate
        ) {
            register(forcedUpdateModalDelegate: forcedUpdateModalDelegate)
        }

        /// Registers the specified logger domain subscription delegate.
        ///
        /// - Parameter loggerDomainSubscriptionDelegate: The
        ///   delegate to register.
        ///
        /// - SeeAlso: ``LoggerDomainSubscriptionDelegate``
        public func registerLoggerDomainSubscriptionDelegate(
            _ loggerDomainSubscriptionDelegate: LoggerDomainSubscriptionDelegate
        ) {
            register(loggerDomainSubscriptionDelegate: loggerDomainSubscriptionDelegate)
        }

        /// Registers the specified permanent user defaults key
        /// delegate.
        ///
        /// - Parameter permanentPersistentStorageKeyDelegate: The
        ///   delegate to register.
        ///
        /// - SeeAlso: ``PermanentPersistentStorageKeyDelegate``
        public func registerPermanentPersistentStorageKeyDelegate(
            _ permanentPersistentStorageKeyDelegate: PermanentPersistentStorageKeyDelegate
        ) {
            register(permanentPersistentStorageKeyDelegate: permanentPersistentStorageKeyDelegate)
        }

        /// Registers the specified UI theme list delegate.
        ///
        /// - Parameter uiThemeListDelegate: The delegate to
        ///   register.
        ///
        /// - SeeAlso: ``UIThemeListDelegate``
        public func registerUIThemeListDelegate(
            _ uiThemeListDelegate: UIThemeListDelegate
        ) {
            register(uiThemeListDelegate: uiThemeListDelegate)
        }
    }
}

// swiftlint:enable identifier_name
