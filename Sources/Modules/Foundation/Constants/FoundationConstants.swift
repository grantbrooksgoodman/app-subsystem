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

    static let appIconImage: CacheDomain = .init("appIconImage") { clearAppIconImageCache() }
    static let encodedHash: CacheDomain = .init("encodedHash") { clearEncodedHashCache() }
    static let localization: CacheDomain = .init("localization") { clearLocalizationCache() }
    static let localTranslationArchive: CacheDomain = .init("localTranslationArchive") { clearLocalTranslationArchiveCache() }

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
        Localization.clearCache()
    }

    private static func clearLocalTranslationArchiveCache() {
        @Dependency(\.translationArchiverDelegate) var translationArchiverDelegate: TranslationArchiverDelegate
        translationArchiverDelegate.clearArchive()
    }
}

public extension ColoredItemType {
    static let accent: ColoredItemType = .init("accent")
    static let background: ColoredItemType = .init("background")
    static let disabled: ColoredItemType = .init("disabled")
    static let groupedContentBackground: ColoredItemType = .init("groupedContentBackground")

    static let navigationBarBackground: ColoredItemType = .init("navigationBarBackground")
    static let navigationBarTitle: ColoredItemType = .init("navigationBarTitle")

    static let subtitleText: ColoredItemType = .init("subtitleText")
    static let titleText: ColoredItemType = .init("titleText")
}

public extension LoggerDomain {
    static let alertKit: LoggerDomain = .init("alertKit")
    static let caches: LoggerDomain = .init("caches")
    static let concurrency: LoggerDomain = .init("concurrency")
    static let general: LoggerDomain = .init("general")
    static let observer: LoggerDomain = .init("observer")
    static let translation: LoggerDomain = .init("translation")
}

public extension StoredItemKey {
    static let languageCode: StoredItemKey = .init("languageCode")
    static let languageCodeDictionary: StoredItemKey = .init("languageCodeDictionary")
    static let overriddenLanguageCode: StoredItemKey = .init("overriddenLanguageCode")
}

extension UserDefaultsKey {
    static let subsystemKeys: [UserDefaultsKey] = [
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

    static let breadcrumbsCaptureEnabled: UserDefaultsKey = .init("breadcrumbsCaptureEnabled")
    static let breadcrumbsCaptureHistory: UserDefaultsKey = .init("breadcrumbsCaptureHistory")
    static let breadcrumbsCaptureSavesToPhotos: UserDefaultsKey = .init("breadcrumbsCaptureSavesToPhotos")
    static let currentThemeID: UserDefaultsKey = .init("currentThemeID")
    static let hidesBuildInfoOverlay: UserDefaultsKey = .init("hidesBuildInfoOverlay")
    static let isDeveloperModeEnabled: UserDefaultsKey = .init("isDeveloperModeEnabled")
    static let isGlassTintingEnabled: UserDefaultsKey = .init("isGlassTintingEnabled")
    static let isTimebombActive: UserDefaultsKey = .init("isTimebombActive")
    static let pendingThemeID: UserDefaultsKey = .init("pendingThemeID")
    static let translationArchive: UserDefaultsKey = .init("translationArchive")
}

// MARK: - Observable Registry

/// A registry of app-wide ``Observable`` values used to
/// drive reactive UI updates and cross-component communication.
public enum Observables {
    public static let breadcrumbsDidCapture = Observable<Nil>()

    static let isBuildInfoOverlayHidden = Observable<Bool>(true)
    static let rootViewSheet = Observable<AnyView?>(nil)
    static let rootViewTapped = Observable<Nil>()
    static let rootViewToast = Observable<Toast?>(nil)
    static let rootViewToastAction: Observable < (@Sendable () -> Void)?> = .init(nil)
    static let themedViewAppearanceChanged = Observable<Nil>()
}
