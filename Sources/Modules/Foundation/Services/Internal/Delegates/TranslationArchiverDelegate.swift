//
//  TranslationArchiverDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

/* Proprietary */
import Translator

final class LocalTranslationArchiverDelegate: TranslationArchiverDelegate, @unchecked Sendable {
    // MARK: - Constants Accessors

    private typealias Floats = FoundationConstants.CGFloats.LocalTranslationArchiverDelegate

    // MARK: - Properties

    private let ioLock = NSRecursiveLock()

    /// Serializes disk writes off the calling thread; lookups and mutations
    /// operate on the in-memory archive and never wait for the disk.
    private let persistenceQueue = DispatchQueue(
        label: "us.neotechnica.app-subsystem.translation-archiver-persistence",
        qos: .utility
    )

    /// Maps "<input value hash>|<language pair>" to its translation for
    /// constant-time lookups, avoiding a per-entry hash computation on every
    /// query. The index is the archive's only in-memory copy; writes persist
    /// its values.
    private var archiveIndex = [String: Translation]()

    /// Whether the archive has been loaded from disk, which happens at most
    /// once per launch.
    private var isArchiveLoaded = false

    /// Whether a write of the archive is scheduled and has yet to run.
    private var isWritePending = false

    @Persistent(.translationArchive) private var persistedArchive: Set<Translation>?

    // MARK: - Init

    init() {
        @Dependency(\.notificationCenter) var notificationCenter: NotificationCenter

        // Decode and index the archive ahead of the first lookup, keeping the
        // one-time cost off both the launch path and the translation path.
        persistenceQueue.async {
            self.ioLock.lock()
            defer { self.ioLock.unlock() }
            self.loadArchiveIfNeeded()
        }

        // A pending write reaches the disk before the app can be suspended
        // or terminated.
        for name in [
            UIApplication.didEnterBackgroundNotification,
            UIApplication.willTerminateNotification,
        ] {
            notificationCenter.addObserver(
                self,
                name: name
            ) { [weak self] _ in
                guard let self else { return }
                persistenceQueue.sync { self.persistPendingArchive() }
            }
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

        loadArchiveIfNeeded()
        guard insert(translation) else { return }
        schedulePersistence()
    }

    func addValues(_ translations: Set<Translation>) {
        ioLock.lock()
        defer { ioLock.unlock() }

        loadArchiveIfNeeded()
        var didChangeArchive = false
        for translation in translations {
            didChangeArchive = insert(translation) || didChangeArchive
        }

        guard didChangeArchive else { return }
        schedulePersistence()
    }

    // MARK: - Get Value

    func getValue(
        inputValueEncodedHash hash: String,
        languagePair: LanguagePair
    ) -> Translation? {
        ioLock.lock()
        defer { ioLock.unlock() }

        loadArchiveIfNeeded()
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

        loadArchiveIfNeeded()
        guard archiveIndex.removeValue(forKey: indexKey(
            inputValueEncodedHash: hash,
            languagePair: languagePair
        )) != nil else { return }

        schedulePersistence()
    }

    // MARK: - Clear Archive

    func clearArchive() {
        ioLock.lock()
        defer { ioLock.unlock() }

        archiveIndex = [:]
        isArchiveLoaded = true
        schedulePersistence()
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

    /// Inserts the translation into the index, replacing any existing
    /// translation for the same input and language pair. Returns `false`
    /// when the index already holds the translation.
    private func insert(_ translation: Translation) -> Bool {
        let key = indexKey(for: translation)
        guard archiveIndex[key] != translation else { return false }
        archiveIndex[key] = translation
        return true
    }

    private func loadArchiveIfNeeded() {
        guard !isArchiveLoaded else { return }
        isArchiveLoaded = true
        archiveIndex = (persistedArchive ?? []).reduce(into: [String: Translation]()) { index, translation in
            index[indexKey(for: translation)] = translation
        }
    }

    /// Writes the archive if a write is pending. Runs on the persistence
    /// queue.
    private func persistPendingArchive() {
        let archive: Set<Translation>? = ioLock.withLock {
            guard isWritePending else { return nil }
            isWritePending = false
            return Set(archiveIndex.values)
        }

        guard let archive else { return }
        persistedArchive = archive.isEmpty ? nil : archive
    }

    /// Schedules a write of the archive on the persistence queue. Every change
    /// made before the write runs is coalesced into it, so a burst of changes
    /// encodes the archive once. Call while holding the I/O lock.
    private func schedulePersistence() {
        guard !isWritePending else { return }
        isWritePending = true

        persistenceQueue.asyncAfter(
            deadline: .now() + .milliseconds(Int(Floats.writeDelayMilliseconds))
        ) {
            self.persistPendingArchive()
        }
    }
}
