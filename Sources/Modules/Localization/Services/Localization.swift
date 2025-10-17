//
//  Localization.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

enum Localization {
    // MARK: - Types

    private enum CacheKey: String, CaseIterable {
        case localizedStrings
    }

    // MARK: - Properties

    @Cached(CacheKey.localizedStrings) private static var cachedLocalizedStrings: [String: [String: String]]?

    // MARK: - Computed Properties

    private static var localizedStrings: [String: [String: String]] {
        @Dependency(\.mainBundle) var mainBundle: Bundle
        if let cachedLocalizedStrings,
           !cachedLocalizedStrings.isEmpty {
            return cachedLocalizedStrings
        }

        guard let filePath = mainBundle.url(forResource: "LocalizedStrings", withExtension: "plist"),
              let data = try? Data(contentsOf: filePath),
              let dictionary = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: [String: String]] else {
            return .init()
        }

        cachedLocalizedStrings = dictionary
        return dictionary
    }

    // MARK: - Initialize

    static func initialize() {
        @Dependency(\.coreKit.utils) var coreUtilities: CoreKit.Utilities

        let unsupportedLanguageCodes = ["ba", "ceb", "jv", "la", "mr", "ms", "udm"]
        let supportedLanguages = localizedStrings["language_codes"]?.filter { !unsupportedLanguageCodes.contains($0.key) } ?? [:]
        RuntimeStorage.store(supportedLanguages, as: .languageCodeDictionary)

        if RuntimeStorage.languageCodeDictionary?[RuntimeStorage.languageCode] == nil || supportedLanguages.isEmpty {
            Logger.log(.init(
                "Unsupported language code; reverting to English.",
                metadata: .init(sender: self)
            ))

            coreUtilities.setLanguageCode("en")
        }
    }

    // MARK: - String for Key

    static func string(
        for key: any LocalizedStringKeyRepresentable,
        language languageCode: String
    ) -> String {
        guard !localizedStrings.isEmpty else { return "�" }
        guard let valuesForKey = localizedStrings[key.referent],
              let localizedString = valuesForKey[languageCode] else {
            guard languageCode != "en" else { return "�" }
            return string(for: key, language: "en")
        }
        return localizedString
    }

    // MARK: - Clear Cache

    static func clearCache() {
        cachedLocalizedStrings = nil
    }
}
