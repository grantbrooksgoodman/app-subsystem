//
//  LocalizationResolver.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/* Proprietary */
import Translator

enum LocalizedStringResolver {
    // MARK: - Properties

    private static let cachedLocalizedStrings = LockIsolated<[LocalizationSource: [String: [String: String]]]?>(nil)

    // MARK: - Initialize

    static func initialize() {
        @Dependency(\.coreKit.utils) var coreUtilities: CoreKit.Utilities

        let unsupportedLanguageCodes = ["ba", "ceb", "jv", "la", "mr", "ms", "udm"]
        let supportedLanguages = localizedStrings(for: .subsystem)["language_codes"]?.filter {
            !unsupportedLanguageCodes.contains($0.key)
        } ?? [:]

        RuntimeStorage.store(
            supportedLanguages,
            as: .languageCodeDictionary
        )

        if RuntimeStorage.languageCodeDictionary?[RuntimeStorage.languageCode] == nil ||
            supportedLanguages.isEmpty {
            Logger.log(
                .init(
                    "Unsupported language code; reverting to English.",
                    userInfo: ["LanguageCode": RuntimeStorage.languageCode],
                    metadata: .init(sender: self)
                ),
                domain: .localization
            )

            coreUtilities.setLanguageCode("en")
        }
    }

    // MARK: - String for Key

    static func string(
        for key: any LocalizedStringKeyRepresentable,
        language languageCode: String,
        source: LocalizationSource
    ) -> String {
        let localizedStrings = localizedStrings(for: source)

        guard !localizedStrings.isEmpty else { return "�" }
        guard let valuesForKey = localizedStrings[key.referent],
              let localizedString = valuesForKey[languageCode] else {
            guard languageCode != "en" else { return "�" }
            return string(
                for: key,
                language: "en",
                source: source
            )
        }

        return localizedString
    }

    // MARK: - Clear Cache

    static func clearCache() {
        cachedLocalizedStrings.wrappedValue = nil
    }

    // MARK: - Auxiliary

    private static func localizedStrings(
        for source: LocalizationSource
    ) -> [String: [String: String]] {
        if let cached = cachedLocalizedStrings.wrappedValue?[source],
           !cached.isEmpty {
            return cached
        }

        guard let filePath = source.bundle.url(
            forResource: source.plistName,
            withExtension: "plist"
        ),
            let data = try? Data(contentsOf: filePath),
            let dictionary = try? PropertyListSerialization.propertyList(
                from: data,
                format: nil
            ) as? [String: [String: String]] else { return .init() }

        cachedLocalizedStrings.projectedValue.withValue {
            var cachedLocalizedStrings = $0 ?? .init()
            cachedLocalizedStrings[source] = dictionary
            $0 = cachedLocalizedStrings
        }

        return dictionary
    }
}
