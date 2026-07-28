//
//  FoundationConstants.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/* Proprietary */
import Translator

// MARK: - Shared Value Registry

/// A registry of app-wide ``SharedState`` and ``SharedEvent`` values used
/// to drive reactive UI updates and cross-component communication.
public enum Shared {
    /// A signal that fires after Breadcrumbs captures a
    /// screenshot.
    public static let breadcrumbsDidCapture = SharedEvent<Void>()

    static let isBuildInfoOverlayHidden = SharedState<Bool>(true)
    static let rootViewSheet = SharedState<RootSheet?>(nil)
    static let rootViewTapped = SharedEvent<Void>()
    static let rootViewToast = SharedState<Toast?>(nil)
    static let rootViewToastAction = SharedState<(@Sendable () -> Void)?>(nil)
    static let themedViewAppearanceChanged = SharedEvent<Void>()
}

// MARK: - Foundation Constants

enum FoundationConstants {
    /* MARK: CGFloat */

    enum CGFloats {}

    /* MARK: Color */

    enum Colors {}

    /* MARK: String */

    enum Strings {}
}

// MARK: - Included Keys

// TODO: Investigate duplicate ID behavior and theorize potential solutions.

public extension CacheDomain {
    /* MARK: Properties */

    /// The cache domain for localized string lookups.
    static let localization: CacheDomain = .init(
        "localization",
        clear: clearLocalizationCache
    )

    internal static let appIconImage: CacheDomain = .init(
        "appIconImage",
        clear: clearAppIconImageCache
    )

    internal static let encodedHash: CacheDomain = .init(
        "encodedHash",
        clear: clearEncodedHashCache
    )

    internal static let localTranslationArchive: CacheDomain = .init(
        "localTranslationArchive",
        clear: clearLocalTranslationArchiveCache
    )

    internal static let persistence: CacheDomain = .init(
        "persistence",
        clear: clearPersistenceCache
    )

    /* MARK: Methods */

    private static func clearAppIconImageCache() {
        Task { @MainActor in
            AppIconImageUtility.shared.clearCache()
        }
    }

    private static func clearEncodedHashCache() {
        EncodedHashStore.clearStore()
    }

    private static func clearLocalizationCache() {
        LocalizedStringResolver.clearCache()
    }

    private static func clearLocalTranslationArchiveCache() {
        @Dependency(\.translationArchiverDelegate) var translationArchiverDelegate: TranslationArchiverDelegate
        translationArchiverDelegate.clearArchive()
    }

    private static func clearPersistenceCache() {
        PersistenceCache.clearCache()
    }
}

public extension ColoredItemType {
    /// A color that reflects the accent color of the system or app.
    static let accent: ColoredItemType = .init("accent")

    /// The background color.
    static let background: ColoredItemType = .init("background")

    /// The color for controls in a disabled state.
    static let disabled: ColoredItemType = .init("disabled")

    /// The background color for grouped content areas.
    static let groupedContentBackground: ColoredItemType = .init("groupedContentBackground")

    /// The navigation bar background color.
    static let navigationBarBackground: ColoredItemType = .init("navigationBarBackground")

    /// The navigation bar title text color.
    static let navigationBarTitle: ColoredItemType = .init("navigationBarTitle")

    /// The color for subtitle text.
    static let subtitleText: ColoredItemType = .init("subtitleText")

    /// The color for title text.
    static let titleText: ColoredItemType = .init("titleText")
}

public extension LoggerDomain {
    /// Log messages originating from AlertKit.
    static let alertKit: LoggerDomain = .init("alertKit")

    /// Log messages related to cache operations.
    static let caches: LoggerDomain = .init("caches")

    /// Log messages related to concurrency operations.
    static let concurrency: LoggerDomain = .init("concurrency")

    /// General-purpose log messages.
    static let general: LoggerDomain = .init("general")

    /// Log messages related to localization.
    static let localization: LoggerDomain = .init("localization")

    /// Log messages related to observer registration and
    /// notification.
    static let observer: LoggerDomain = .init("observer")

    /// Log messages related to translation operations.
    static let translation: LoggerDomain = .init("translation")
}

public extension StoredItemKey {
    /// The active language code for the current session.
    static let languageCode: StoredItemKey = .init("languageCode")

    /// The dictionary mapping language codes to their
    /// display names.
    static let languageCodeDictionary: StoredItemKey = .init("languageCodeDictionary")

    /// A language code override set at runtime.
    static let overriddenLanguageCode: StoredItemKey = .init("overriddenLanguageCode")
}

extension PersistentStorageKey {
    static let subsystemKeys: [PersistentStorageKey] = [
        .breadcrumbsCaptureEnabled,
        .breadcrumbsCaptureHistory,
        .breadcrumbsCaptureSavesToPhotos,
        .currentThemeID,
        .hidesBuildInfoOverlay,
        .isDeveloperModeEnabled,
        .isGlassTintingEnabled,
        .isTimebombActive,
        .pendingThemeID,
        .translationArchive,
    ]

    static let breadcrumbsCaptureEnabled: PersistentStorageKey = .init("breadcrumbsCaptureEnabled")
    static let breadcrumbsCaptureHistory: PersistentStorageKey = .init("breadcrumbsCaptureHistory")
    static let breadcrumbsCaptureSavesToPhotos: PersistentStorageKey = .init("breadcrumbsCaptureSavesToPhotos")
    static let currentThemeID: PersistentStorageKey = .init("currentThemeID")
    static let hidesBuildInfoOverlay: PersistentStorageKey = .init("hidesBuildInfoOverlay")
    static let isDeveloperModeEnabled: PersistentStorageKey = .init("isDeveloperModeEnabled")
    static let isGlassTintingEnabled: PersistentStorageKey = .init("isGlassTintingEnabled")
    static let isTimebombActive: PersistentStorageKey = .init("isTimebombActive")
    static let pendingThemeID: PersistentStorageKey = .init("pendingThemeID")
    static let translationArchive: PersistentStorageKey = .init("translationArchive")
}
