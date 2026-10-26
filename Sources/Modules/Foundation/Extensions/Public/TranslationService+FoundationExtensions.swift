//
//  TranslationService+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

@preconcurrency import Translator
import UIKit

public extension TranslationService {
    /// Translates the given inputs asynchronously, with optional HUD
    /// and timeout support.
    ///
    /// This is the primary translation entry point used throughout
    /// the subsystem. It wraps the underlying completion-based
    /// translation pipeline in a Swift concurrency interface and
    /// layers two optional behaviors on top:
    ///
    /// - **HUD** – When `hudConfig` is provided, a progress HUD is
    ///   shown after the specified delay and dismissed when
    ///   translation completes. Set `isModal` to `true` to block
    ///   user interaction while the HUD is visible.
    /// - **Timeout** – If translation does not complete within the
    ///   configured duration, the method resolves with the
    ///   translations received so far. Any inputs that have not yet
    ///   been translated are filled in with their original
    ///   (untranslated) values when `returnsInputs` is `true`. When
    ///   `returnsInputs` is `false`, a timed-out request fails with
    ///   an ``Exception``.
    ///
    /// - Parameters:
    ///   - inputs: The translation inputs to translate.
    ///   - languagePair: The source and target language pair.
    ///   - hudConfig: An optional tuple controlling the progress
    ///     HUD. `appearsAfter` is the delay before the HUD is
    ///     shown; `isModal` controls whether user interaction is
    ///     blocked. Pass `nil` to suppress the HUD.
    ///   - timeoutConfig: A tuple controlling timeout behavior.
    ///     `duration` is how long to wait before timing out;
    ///     `returnsInputs` determines whether a timed-out request
    ///     falls back to original input values (`true`) or fails
    ///     with an exception (`false`). The default is 10 seconds
    ///     with fallback enabled.
    ///
    /// - Returns: The translated values.
    ///
    /// - Throws: An ``Exception`` if the translation fails.
    func getTranslations(
        _ inputs: [TranslationInput],
        languagePair: LanguagePair,
        hud hudConfig: (appearsAfter: Duration, isModal: Bool)? = nil,
        timeout timeoutConfig: (duration: Duration, returnsInputs: Bool) = (.seconds(10), true)
    ) async throws(Exception) -> [Translation] {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                getTranslations(
                    inputs,
                    languagePair: languagePair,
                    hud: hudConfig,
                    timeout: timeoutConfig
                ) { result in
                    switch result {
                    case let .success(translations):
                        continuation.resume(returning: translations)

                    case let .failure(exception):
                        continuation.resume(throwing: exception)
                    }
                }
            }
        } catch {
            guard let exception = error as? Exception else {
                throw Exception(
                    error,
                    metadata: .init(sender: self)
                )
            }

            throw exception
        }
    }

    /// Resolves a ``TranslatedLabelStrings`` conformance by
    /// translating all of its key pairs into output maps.
    ///
    /// This method translates every input defined by the given
    /// ``TranslatedLabelStrings`` type using the system language
    /// pair. Each translated result is mapped back to its
    /// corresponding ``TranslatedLabelStringKey``. If a particular
    /// translation is not found in the response, its
    /// ``TranslationInputMap/defaultOutputMap`` is used as a
    /// fallback.
    ///
    /// ```swift
    /// let outputMaps = try await translator.resolve(
    ///     MyStrings.self
    /// )
    /// ```
    ///
    /// - Parameter strings: The ``TranslatedLabelStrings`` type
    ///   whose key pairs should be resolved.
    ///
    /// - Returns: An array of ``TranslationOutputMap`` values.
    ///
    /// - Throws: An ``Exception`` if the translation fails.
    func resolve(
        _ strings: TranslatedLabelStrings.Type
    ) async throws(Exception) -> [TranslationOutputMap] {
        let translations: [Translation]

        do {
            translations = try await getTranslations(
                strings.keyPairs.map(\.input),
                languagePair: .system
            )
        } catch {
            throw Exception(
                error,
                metadata: .init(sender: self)
            )
        }

        return strings
            .keyPairs
            .reduce(into: [TranslationOutputMap]()) { partialResult, keyPair in
                if let translation = translations.first(where: {
                    $0.input.value == keyPair.input.value
                }) {
                    partialResult.append(.init(
                        key: keyPair.key,
                        value: translation.output
                    ))
                } else {
                    partialResult.append(keyPair.defaultOutputMap)
                }
            }
    }

    /// Translates a single input asynchronously, with optional HUD
    /// and timeout support.
    ///
    /// This is a convenience wrapper around
    /// ``getTranslations(_:languagePair:hud:timeout:)`` for the
    /// common case of translating a single value. It returns the
    /// first translation from the result, or throws an
    /// ``Exception`` if the response is empty.
    ///
    /// - Parameters:
    ///   - input: The translation input to translate.
    ///   - languagePair: The source and target language pair.
    ///   - hudConfig: An optional tuple controlling the progress
    ///     HUD. Pass `nil` to suppress the HUD.
    ///   - timeoutConfig: A tuple controlling timeout behavior. The
    ///     default is 10 seconds with input-value fallback enabled.
    ///
    /// - Returns: The completed translation.
    ///
    /// - Throws: An ``Exception`` if the translation fails.
    func translate(
        _ input: TranslationInput,
        languagePair: LanguagePair,
        hud hudConfig: (appearsAfter: Duration, isModal: Bool)? = nil,
        timeout timeoutConfig: (duration: Duration, returnsInputs: Bool) = (.seconds(10), true)
    ) async throws(Exception) -> Translation {
        guard let translation = try await getTranslations(
            [input],
            languagePair: languagePair,
            hud: hudConfig,
            timeout: timeoutConfig
        ).first else {
            throw Exception(
                metadata: .init(sender: self)
            )
        }

        return translation
    }

    private func getTranslations(
        _ inputs: [TranslationInput],
        languagePair: LanguagePair,
        hud hudConfig: (appearsAfter: Duration, isModal: Bool)?,
        timeout timeoutConfig: (duration: Duration, returnsInputs: Bool),
        completion: @Sendable @escaping (Callback<[Translation], Exception>) -> Void
    ) {
        @Dependency(\.coreKit.hud) var coreHUD: CoreKit.HUD
        @Dependency(\.translationService) var translator: TranslationService

        let didComplete = LockIsolated(false)
        let exception = LockIsolated<Exception?>(nil)
        let translations = LockIsolated([Translation]())

        if let hudConfig {
            Task.delayed(by: hudConfig.appearsAfter) { @MainActor in
                guard !didComplete.wrappedValue else { return }
                coreHUD.showProgress(isModal: hudConfig.isModal)
            }
        }

        var canComplete: Bool {
            didComplete.projectedValue.withValue {
                guard !$0 else { return false }
                $0 = true
                return true
            }
        }

        @Sendable
        func complete(timedOut: Bool) {
            guard canComplete else { return }
            if hudConfig != nil {
                Task { @MainActor in
                    @Dependency(\.coreKit.hud) var coreHUD: CoreKit.HUD
                    coreHUD.hide()
                }
            }

            let currentException = exception.wrappedValue
            let currentTranslations = translations.wrappedValue

            if let currentException {
                guard timeoutConfig.returnsInputs else {
                    return completion(.failure(currentException))
                }

                Logger.log(
                    currentException,
                    domain: .translation
                )

                return completion(.success(currentTranslations))
            }

            guard currentTranslations.count == inputs.count else {
                return completion(.failure(.init(
                    "Mismatched ratio returned.",
                    metadata: .init(sender: self)
                )))
            }

            if timedOut {
                guard timeoutConfig.returnsInputs else {
                    return completion(.failure(.timedOut(
                        metadata: .init(sender: self)
                    )))
                }

                Logger.log(
                    .timedOut(metadata: .init(sender: self)),
                    domain: .translation
                )
            }

            return completion(.success(currentTranslations))
        }

        let timeout = Timeout(after: timeoutConfig.duration) {
            translations.projectedValue.withValue { existingTranslations in
                let missingTranslations = inputs.filter { input in
                    !existingTranslations.map(\.input).contains(input)
                }

                let fallbackTranslations = missingTranslations.map { input in
                    Translation(
                        input: input,
                        output: input.original.sanitized,
                        languagePair: languagePair
                    )
                }

                existingTranslations.append(contentsOf: fallbackTranslations)
            }

            return complete(timedOut: true)
        }

        Task {
            do {
                translations.wrappedValue = try await translator.getTranslations(
                    inputs,
                    languagePair: languagePair
                )
            } catch {
                exception.wrappedValue = .init(
                    error,
                    metadata: .init(sender: self)
                )
            }

            timeout.cancel()
            return complete(timedOut: false)
        }
    }
}
