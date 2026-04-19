//
//  LanguagePair+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/* Proprietary */
import Translator

public extension LanguagePair {
    /// A language pair from English to the current system language.
    static var system: LanguagePair {
        .init(from: "en", to: RuntimeStorage.languageCode)
    }
}
