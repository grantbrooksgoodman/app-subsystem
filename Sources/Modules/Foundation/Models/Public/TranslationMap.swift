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

/// A pairing of a translatable label key with its translation input.
///
/// Each `TranslationInputMap` associates a
/// ``TranslatedLabelStringCollection`` key with a `TranslationInput`
/// that provides the original string and an optional alternate value.
///
/// The subsystem passes these maps to the translation service, which
/// returns the corresponding ``TranslationOutputMap`` values.
///
/// - SeeAlso: ``TranslationOutputMap``,
///   ``TranslatedLabelStrings``
public struct TranslationInputMap: Equatable {
    // MARK: - Properties

    /// The translation input for the string.
    public let input: TranslationInput

    /// The key that identifies the translatable label.
    public let key: TranslatedLabelStringCollection

    // MARK: - Computed Properties

    /// A default output map for this input.
    ///
    /// Returns the original English string when the active language
    /// code is `"en"`, or the stored translation value otherwise.
    /// Use this property as a fallback when
    /// translation results are not yet available or fail to resolve.
    public var defaultOutputMap: TranslationOutputMap {
        .init(
            key: key,
            value: RuntimeStorage.languageCode == "en" ? input.original.sanitized : input.value.sanitized
        )
    }

    // MARK: - Init

    /// Creates a translation input map.
    ///
    /// - Parameters:
    ///   - key: The key that identifies the translatable label.
    ///   - input: The translation input for the string.
    public init(
        key: TranslatedLabelStringCollection,
        input: TranslationInput
    ) {
        self.key = key
        self.input = input
    }
}

/// A pairing of a translatable label key with its resolved
/// translation value.
///
/// After the translation service processes a ``TranslationInputMap``,
/// the result is delivered as a `TranslationOutputMap`. Use the
/// ``value`` property to retrieve the translated string for the
/// corresponding ``key``.
///
/// - SeeAlso: ``TranslationInputMap``,
///   ``TranslatedLabelStrings``
public struct TranslationOutputMap: Equatable, Sendable {
    // MARK: - Properties

    /// The key that identifies the translatable label.
    public let key: TranslatedLabelStringCollection

    /// The translated string.
    public let value: String

    // MARK: - Init

    /// Creates a translation output map.
    ///
    /// - Parameters:
    ///   - key: The key that identifies the translatable label.
    ///   - value: The translated string.
    public init(
        key: TranslatedLabelStringCollection,
        value: String
    ) {
        self.key = key
        self.value = value
    }
}
