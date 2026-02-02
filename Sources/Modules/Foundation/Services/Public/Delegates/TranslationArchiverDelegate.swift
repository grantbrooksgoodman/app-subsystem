//
//  TranslationArchiverDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/* Proprietary */
import Translator

public final class LocalTranslationArchiverDelegate: TranslationArchiverDelegate {
    // MARK: - Properties

    @LockIsolated private var archive = Set<Translation>() {
        didSet { persistedArchive = archive.isEmpty ? nil : archive }
    }

    @Persistent(.translationArchive) private var persistedArchive: Set<Translation>?
    @LockIsolated private var translationsForInputValueEncodedHashes = [String: Translation]()

    // MARK: - Init

    fileprivate init() { archive = persistedArchive ?? [] }

    // MARK: - Register with Dependencies

    public static func registerWithDependencies() {
        @Dependency(\.translatorConfig) var translatorConfig: Translator.Config
        translatorConfig.registerArchiverDelegate(LocalTranslationArchiverDelegate())
    }

    // MARK: - Add Value

    public func addValue(_ translation: Translation) {
        archive.insert(translation)
        translationsForInputValueEncodedHashes = translationsForInputValueEncodedHashes
            .filter { $0.value != translation }
    }

    public func addValues(_ translations: Set<Translation>) {
        archive.formUnion(translations)
        translationsForInputValueEncodedHashes = translationsForInputValueEncodedHashes
            .filter { !translations.contains($0.value) }
    }

    // MARK: - Get Value

    public func getValue(
        inputValueEncodedHash hash: String,
        languagePair: LanguagePair
    ) -> Translation? {
        if let value = translationsForInputValueEncodedHashes[hash],
           value.languagePair == languagePair {
            return value
        }

        guard let translation = archive.first(where: {
            $0.input.value.encodedHash == hash && $0.languagePair == languagePair
        }) else { return nil }

        translationsForInputValueEncodedHashes[hash] = translation
        return translation
    }

    // MARK: - Remove Value

    public func removeValue(
        inputValueEncodedHash hash: String,
        languagePair: LanguagePair
    ) {
        func satisfiesConstraints(_ translation: Translation) -> Bool {
            translation.input.value.encodedHash == hash && translation.languagePair == languagePair
        }

        if let value = getValue(
            inputValueEncodedHash: hash,
            languagePair: languagePair
        ) {
            archive.remove(value)
        }

        translationsForInputValueEncodedHashes = translationsForInputValueEncodedHashes
            .filter { !satisfiesConstraints($0.value) }
    }

    // MARK: - Clear Archive

    public func clearArchive() {
        archive = []
        translationsForInputValueEncodedHashes = [:]
    }
}

/* MARK: Dependency */

public enum TranslationArchiverDelegateDependency: DependencyKey {
    public static func resolve(_ dependencies: DependencyValues) -> TranslationArchiverDelegate {
        dependencies.translatorConfig.archiverDelegate ?? LocalTranslationArchiverDelegate()
    }
}

public extension DependencyValues {
    var translationArchiverDelegate: TranslationArchiverDelegate {
        get { self[TranslationArchiverDelegateDependency.self] }
        set { self[TranslationArchiverDelegateDependency.self] = newValue }
    }
}
