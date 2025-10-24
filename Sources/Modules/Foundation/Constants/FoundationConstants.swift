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

    public enum CGFloats {}

    /* MARK: Color */

    public enum Colors {}

    /* MARK: String */

    public enum Strings {}
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
        AppIconImageUtility.shared.clearCache()
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
    static let isTimebombActive: UserDefaultsKey = .init("isTimebombActive")
    static let pendingThemeID: UserDefaultsKey = .init("pendingThemeID")
    static let translationArchive: UserDefaultsKey = .init("translationArchive")
}

// MARK: - Observable Registry

public enum Observables {
    public static let breadcrumbsDidCapture: Observable<Nil> = .init(key: .breadcrumbsDidCapture)

    static let isBuildInfoOverlayHidden: Observable<Bool> = .init(.isBuildInfoOverlayHidden, true)
    static let rootViewSheet: Observable<AnyView?> = .init(.rootViewSheet, nil)
    static let rootViewTapped: Observable<Nil> = .init(key: .rootViewTapped)
    static let rootViewToast: Observable<Toast?> = .init(.rootViewToast, nil)
    static let rootViewToastAction: Observable<(() -> Void)?> = .init(.rootViewToastAction, nil)
    static let themedViewAppearanceChanged: Observable<Nil> = .init(key: .themedViewAppearanceChanged)
}

extension ObservableKey {
    static let breadcrumbsDidCapture: ObservableKey = .init("breadcrumbsDidCapture")
    static let isBuildInfoOverlayHidden: ObservableKey = .init("isBuildInfoOverlayHidden")
    static let rootViewSheet: ObservableKey = .init("rootViewSheet")
    static let rootViewTapped: ObservableKey = .init("rootViewTapped")
    static let rootViewToast: ObservableKey = .init("rootViewToast")
    static let rootViewToastAction: ObservableKey = .init("rootViewToastAction")
    static let themedViewAppearanceChanged: ObservableKey = .init("themedViewAppearanceChanged")
}

// MARK: - Default Localized Strings

extension AppSubsystem.Delegates.DefaultLocalizedStringsDelegate {
    static let cancelString = "Cancel"
    static let dismissString = "Dismiss"
    static let doneString = "Done"
    static let errorReportedString = "This error has been reported."
    static let internetConnectionOfflineString = "Internet connection is offline."
    static let noEmailString = "It appears that your device is not able to send e-mail.\n\nPlease verify that your e-mail client is set up and try again."
    static let noInternetMessageString = "The internet connection appears to be offline.\n\nPlease connect to the internet and try again."
    static let reportBugString = "Report Bug"
    static let reportSentString = "Report sent"
    static let sendFeedbackString = "Send Feedback"
    static let settingsString = "Settings..."
    static let somethingWentWrongString = "Something went wrong, please try again later."
    static let tapToReportString = "Tap to report this error."
    static let timedOutString = "The operation timed out. Please try again later."
    static let tryAgainString = "Try Again"
    static let yesterdayString = "Yesterday"
}
