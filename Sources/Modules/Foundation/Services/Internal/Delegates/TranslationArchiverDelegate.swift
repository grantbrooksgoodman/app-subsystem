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

final class LocalTranslationArchiverDelegate: TranslationArchiverDelegate, @unchecked Sendable {
    // MARK: - Properties

    private let archive = LockIsolated(Set<Translation>())
    private let translationsForInputValueEncodedHashes = LockIsolated([String: Translation]())

    @Persistent(.translationArchive) private var persistedArchive: Set<Translation>?

    // MARK: - Init

    init() {
        archive.wrappedValue = persistedArchive ?? []
    }

    // MARK: - Register with Dependencies

    static func registerWithDependencies() {
        @Dependency(\.translatorConfig) var translatorConfig: Translator.Config
        translatorConfig.registerArchiverDelegate(LocalTranslationArchiverDelegate())
    }

    // MARK: - Add Value

    func addValue(_ translation: Translation) {
        archive.projectedValue.insert(translation)
        persistArchive()

        translationsForInputValueEncodedHashes.projectedValue.withValue {
            $0 = $0.filter { $0.value != translation }
        }
    }

    func addValues(_ translations: Set<Translation>) {
        archive.projectedValue.formUnion(translations)
        persistArchive()

        translationsForInputValueEncodedHashes.projectedValue.withValue {
            $0 = $0.filter { !translations.contains($0.value) }
        }
    }

    // MARK: - Get Value

    func getValue(
        inputValueEncodedHash hash: String,
        languagePair: LanguagePair
    ) -> Translation? {
        if let value = translationsForInputValueEncodedHashes.projectedValue[hash],
           value.languagePair == languagePair {
            return value
        }

        guard let translation = archive.wrappedValue.first(where: {
            $0.input.value.encodedHash == hash && $0.languagePair == languagePair
        }) else { return nil }

        translationsForInputValueEncodedHashes.projectedValue[hash] = translation
        return translation
    }

    // MARK: - Remove Value

    func removeValue(
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
            archive.projectedValue.remove(value)
            persistArchive()
        }

        translationsForInputValueEncodedHashes.projectedValue.withValue {
            $0 = $0.filter { !satisfiesConstraints($0.value) }
        }
    }

    // MARK: - Clear Archive

    func clearArchive() {
        archive.wrappedValue = []
        persistedArchive = nil
        translationsForInputValueEncodedHashes.wrappedValue = [:]
    }

    // MARK: - Auxiliary

    private func persistArchive() {
        let archiveSnapshot = archive.wrappedValue
        persistedArchive = archiveSnapshot.isEmpty ? nil : archiveSnapshot
    }
}
