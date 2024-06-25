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
    static var system: LanguagePair {
        .init(from: "en", to: RuntimeStorage.languageCode)
    }
}
