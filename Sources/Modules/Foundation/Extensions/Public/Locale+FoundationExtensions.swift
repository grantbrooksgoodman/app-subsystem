//
//  Locale+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension Locale {
    /// The two-letter language code of the device, falling back to
    /// `"en"` when unavailable.
    static var systemLanguageCode: String {
        @Dependency(\.mainBundle) var mainBundle: Bundle
        @Dependency(\.currentLocale) var currentLocale: Locale

        let bundleLanguage = mainBundle.preferredLocalizations.first
        let localeLanguage = Locale.preferredLanguages.first
        let currentLocaleLanguage = currentLocale.language.languageCode?.identifier

        let languageCode = bundleLanguage ?? localeLanguage ?? currentLocaleLanguage
        guard let languageCode,
              languageCode.count >= 2 else { return "en" }
        return languageCode.components[0 ... 1].joined()
    }
}
