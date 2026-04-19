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

/// A persistent, on-device archive that caches translations between
/// sessions.
///
/// `LocalTranslationArchiverDelegate` conforms to Translator's
/// `TranslationArchiverDelegate` and stores completed translations in
/// a ``Persistent`` set backed by `UserDefaults`. This allows the
/// translation service to resolve previously fetched translations
/// without a network request.
///
/// ## Registration
///
/// Call ``registerWithDependencies()`` during app setup to install
/// the archiver with the Translator configuration:
///
/// ```swift
/// LocalTranslationArchiverDelegate.registerWithDependencies()
/// ```
///
/// You can also access the archiver through the dependency system:
///
/// ```swift
/// @Dependency(\.translationArchiverDelegate) var archiver: TranslationArchiverDelegate
/// ```
///
/// ## Lookup Performance
///
/// Individual lookups are accelerated by an in-memory cache keyed on
/// the input value's ``EncodedHashable/encodedHash``. The first
/// lookup for a given hash scans the full archive; subsequent lookups
/// for the same hash resolve from the cache.
///
/// - Note: All access to the archive is synchronized using locks, so
///   reads and writes are safe to perform concurrently.
public final class LocalTranslationArchiverDelegate: TranslationArchiverDelegate, @unchecked Sendable {
    // MARK: - Properties

    private let archive = LockIsolated<Set<Translation>>(wrappedValue: [])
    @Persistent(.translationArchive) private var persistedArchive: Set<Translation>?
    private let translationsForInputValueEncodedHashes = LockIsolated<[String: Translation]>(wrappedValue: [:])

    // MARK: - Init

    fileprivate init() { archive.wrappedValue = persistedArchive ?? [] }

    // MARK: - Register with Dependencies

    /// Registers the local translation archiver with the Translator
    /// configuration.
    ///
    /// Call this method once during app setup so that the
    /// translation service can read from and write to the local
    /// archive.
    public static func registerWithDependencies() {
        @Dependency(\.translatorConfig) var translatorConfig: Translator.Config
        translatorConfig.registerArchiverDelegate(LocalTranslationArchiverDelegate())
    }

    // MARK: - Add Value

    /// Adds a single translation to the archive.
    ///
    /// The translation is persisted to `UserDefaults` and the
    /// in-memory lookup cache is invalidated for the corresponding
    /// input hash.
    ///
    /// - Parameter translation: The translation to archive.
    public func addValue(_ translation: Translation) {
        archive.projectedValue.insert(translation)
        persistArchive()

        translationsForInputValueEncodedHashes.projectedValue.withValue {
            $0 = $0.filter { $0.value != translation }
        }
    }

    /// Adds a set of translations to the archive.
    ///
    /// Each translation is persisted to `UserDefaults` and the
    /// in-memory lookup cache is invalidated for the corresponding
    /// input hashes.
    ///
    /// - Parameter translations: The translations to archive.
    public func addValues(_ translations: Set<Translation>) {
        archive.projectedValue.formUnion(translations)
        persistArchive()

        translationsForInputValueEncodedHashes.projectedValue.withValue {
            $0 = $0.filter { !translations.contains($0.value) }
        }
    }

    // MARK: - Get Value

    /// Returns the archived translation matching the given input hash
    /// and language pair, or `nil` if no match is found.
    ///
    /// The first lookup for a given hash scans the full archive and
    /// caches the result in memory. Subsequent lookups for the same
    /// hash resolve from the cache.
    ///
    /// - Parameters:
    ///   - hash: The ``EncodedHashable/encodedHash`` of the
    ///     translation input value.
    ///   - languagePair: The source-to-target language pair.
    /// - Returns: The matching translation, or `nil`.
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

    /// Removes the archived translation matching the given input hash
    /// and language pair.
    ///
    /// Both the persistent archive and the in-memory lookup cache are
    /// updated. If no matching translation exists, this method has no
    /// effect.
    ///
    /// - Parameters:
    ///   - hash: The ``EncodedHashable/encodedHash`` of the
    ///     translation input value.
    ///   - languagePair: The source-to-target language pair.
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

    /// Removes all translations from the archive.
    ///
    /// Both the persistent storage and the in-memory lookup cache
    /// are cleared.
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

/// The dependency key that provides a ``TranslationArchiverDelegate``
/// instance.
public enum TranslationArchiverDelegateDependency: DependencyKey {
    public static func resolve(_ dependencies: DependencyValues) -> TranslationArchiverDelegate {
        dependencies.translatorConfig.archiverDelegate ?? LocalTranslationArchiverDelegate()
    }
}

public extension DependencyValues {
    /// The shared ``TranslationArchiverDelegate`` instance.
    var translationArchiverDelegate: TranslationArchiverDelegate {
        get { self[TranslationArchiverDelegateDependency.self] }
        set { self[TranslationArchiverDelegateDependency.self] = newValue }
    }
}
