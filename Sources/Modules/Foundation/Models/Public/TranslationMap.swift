//
//  TranslationMap.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/* Proprietary */
import Translator

public struct TranslationInputMap: Equatable {
    // MARK: - Properties

    public let key: TranslatedLabelStringCollection
    public let input: TranslationInput

    // MARK: - Computed Properties

    public var defaultOutputMap: TranslationOutputMap {
        .init(key: key, value: RuntimeStorage.languageCode == "en" ? input.original.sanitized : input.value.sanitized)
    }

    // MARK: - Init

    public init(
        key: TranslatedLabelStringCollection,
        input: TranslationInput
    ) {
        self.key = key
        self.input = input
    }
}

public struct TranslationOutputMap: Equatable {
    // MARK: - Properties

    public let key: TranslatedLabelStringCollection
    public let value: String

    // MARK: - Init

    public init(
        key: TranslatedLabelStringCollection,
        value: String
    ) {
        self.key = key
        self.value = value
    }
}
