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

public final class LocalTranslationArchiverDelegate: TranslationArchiverDelegate, @unchecked Sendable {
    // MARK: - Properties

    private let archive = LockIsolated<Set<Translation>>(wrappedValue: [])
    @Persistent(.translationArchive) private var persistedArchive: Set<Translation>?
    private let translationsForInputValueEncodedHashes = LockIsolated<[String: Translation]>(wrappedValue: [:])

    // MARK: - Init

    fileprivate init() { archive.wrappedValue = persistedArchive ?? [] }

    // MARK: - Register with Dependencies

    public static func registerWithDependencies() {
        @Dependency(\.translatorConfig) var translatorConfig: Translator.Config
        translatorConfig.registerArchiverDelegate(LocalTranslationArchiverDelegate())
    }

    // MARK: - Add Value

    public func addValue(_ translation: Translation) {
        archive.projectedValue.insert(translation)
        persistArchive()

        translationsForInputValueEncodedHashes.projectedValue.withValue {
            $0 = $0.filter { $0.value != translation }
        }
    }

    public func addValues(_ translations: Set<Translation>) {
        archive.projectedValue.formUnion(translations)
        persistArchive()

        translationsForInputValueEncodedHashes.projectedValue.withValue {
            $0 = $0.filter { !translations.contains($0.value) }
        }
    }

    // MARK: - Get Value

    public func getValue(
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
            archive.projectedValue.remove(value)
            persistArchive()
        }

        translationsForInputValueEncodedHashes.projectedValue.withValue {
            $0 = $0.filter { !satisfiesConstraints($0.value) }
        }
    }

    // MARK: - Clear Archive

    public func clearArchive() {
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
