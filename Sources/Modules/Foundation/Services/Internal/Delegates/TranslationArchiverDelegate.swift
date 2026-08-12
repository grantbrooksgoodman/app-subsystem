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

    private let ioLock = NSRecursiveLock()

    /// Serializes disk writes off the calling thread; lookups and mutations
    /// operate on the in-memory archive and never wait for the disk.
    private let persistenceQueue = DispatchQueue(
        label: "com.neotechnica.app-subsystem.translation-archiver-persistence",
        qos: .utility
    )

    /// Maps "<input value hash>|<language pair>" to its translation for
    /// constant-time lookups, avoiding a per-entry hash computation on every
    /// query.
    private var archiveIndex = [String: Translation]()

    /// The decoded archive, loaded from disk at most once per launch.
    private var cachedArchive: Set<Translation>?

    @Persistent(.translationArchive) private var persistedArchive: Set<Translation>?

    // MARK: - Init

    init() {
        // Decode and index the archive ahead of the first lookup, keeping the
        // one-time cost off both the launch path and the translation path.
        persistenceQueue.async {
            self.ioLock.lock()
            defer { self.ioLock.unlock() }
            _ = self.loadArchiveIfNeeded()
        }
    }

    // MARK: - Register with Dependencies

    static func registerWithDependencies() {
        @Dependency(\.translatorConfig) var translatorConfig: Translator.Config
        translatorConfig.registerArchiverDelegate(LocalTranslationArchiverDelegate())
    }

    // MARK: - Add Value

    func addValue(_ translation: Translation) {
        ioLock.lock()
        defer { ioLock.unlock() }

        var archive = loadArchiveIfNeeded()
        insert(
            translation,
            into: &archive
        )

        cachedArchive = archive
        persistArchive(archive)
    }

    func addValues(_ translations: Set<Translation>) {
        ioLock.lock()
        defer { ioLock.unlock() }

        var archive = loadArchiveIfNeeded()
        for translation in translations {
            insert(
                translation,
                into: &archive
            )
        }

        cachedArchive = archive
        persistArchive(archive)
    }

    // MARK: - Get Value

    func getValue(
        inputValueEncodedHash hash: String,
        languagePair: LanguagePair
    ) -> Translation? {
        ioLock.lock()
        defer { ioLock.unlock() }

        _ = loadArchiveIfNeeded()
        return archiveIndex[indexKey(
            inputValueEncodedHash: hash,
            languagePair: languagePair
        )]
    }

    // MARK: - Remove Value

    func removeValue(
        inputValueEncodedHash hash: String,
        languagePair: LanguagePair
    ) {
        ioLock.lock()
        defer { ioLock.unlock() }

        guard let value = getValue(
            inputValueEncodedHash: hash,
            languagePair: languagePair
        ) else { return }

        var archive = loadArchiveIfNeeded()
        archive.remove(value)
        archiveIndex[indexKey(
            inputValueEncodedHash: hash,
            languagePair: languagePair
        )] = nil

        cachedArchive = archive
        persistArchive(archive)
    }

    // MARK: - Clear Archive

    func clearArchive() {
        ioLock.lock()
        defer { ioLock.unlock() }

        archiveIndex = [:]
        cachedArchive = []
        persistArchive([])
    }

    // MARK: - Auxiliary

    private func indexKey(
        inputValueEncodedHash hash: String,
        languagePair: LanguagePair
    ) -> String {
        "\(hash)|\(languagePair.string)"
    }

    private func indexKey(for translation: Translation) -> String {
        indexKey(
            inputValueEncodedHash: translation.input.value.encodedHash,
            languagePair: translation.languagePair
        )
    }

    /// Inserts the translation into both the archive and the index, replacing
    /// any existing translation for the same input and language pair.
    private func insert(
        _ translation: Translation,
        into archive: inout Set<Translation>
    ) {
        let key = indexKey(for: translation)
        if let existingTranslation = archiveIndex[key] {
            archive.remove(existingTranslation)
        }

        archive.insert(translation)
        archiveIndex[key] = translation
    }

    private func loadArchiveIfNeeded() -> Set<Translation> {
        if let cachedArchive { return cachedArchive }

        let archive = persistedArchive ?? []
        cachedArchive = archive
        archiveIndex = archive.reduce(into: [String: Translation]()) { index, translation in
            index[indexKey(for: translation)] = translation
        }

        return archive
    }

    /// Writes the archive on a background queue, keeping disk I/O off the
    /// translation path. Writes are serialized in submission order, so the
    /// last snapshot always wins.
    private func persistArchive(_ archive: Set<Translation>) {
        persistenceQueue.async {
            self.persistedArchive = archive.isEmpty ? nil : archive
        }
    }
}
