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
    /// - Returns: A ``Callback`` containing the translations on
    ///   success, or an ``Exception`` on failure.
    func getTranslations(
        _ inputs: [TranslationInput],
        languagePair: LanguagePair,
        hud hudConfig: (appearsAfter: Duration, isModal: Bool)? = nil,
        timeout timeoutConfig: (duration: Duration, returnsInputs: Bool) = (.seconds(10), true)
    ) async -> Callback<[Translation], Exception> {
        await withCheckedContinuation { continuation in
            getTranslations(
                inputs,
                languagePair: languagePair,
                hud: hudConfig,
                timeout: timeoutConfig
            ) { result in
                continuation.resume(returning: result)
            }
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
    /// let result = await translator.resolve(MyStrings.self)
    /// switch result {
    /// case let .success(outputMaps):
    ///     // Apply outputMaps to your view.
    /// case let .failure(exception):
    ///     Logger.log(exception)
    /// }
    /// ```
    ///
    /// - Parameter strings: The ``TranslatedLabelStrings`` type
    ///   whose key pairs should be resolved.
    ///
    /// - Returns: A ``Callback`` containing an array of
    ///   ``TranslationOutputMap`` values on success, or an
    ///   ``Exception`` on failure.
    func resolve(
        _ strings: TranslatedLabelStrings.Type
    ) async -> Callback<[TranslationOutputMap], Exception> {
        let getTranslationsResult = await getTranslations(
            strings.keyPairs.map(\.input),
            languagePair: .system
        )

        switch getTranslationsResult {
        case let .success(translations):
            return .success(
                strings
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
            )

        case let .failure(error):
            return .failure(.init(
                error,
                metadata: .init(sender: self)
            ))
        }
    }

    /// Translates a single input asynchronously, with optional HUD
    /// and timeout support.
    ///
    /// This is a convenience wrapper around
    /// ``getTranslations(_:languagePair:hud:timeout:)`` for the
    /// common case of translating a single value. It returns the
    /// first translation from the result, or fails with an
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
    /// - Returns: A ``Callback`` containing the translation on
    ///   success, or an ``Exception`` on failure.
    func translate(
        _ input: TranslationInput,
        languagePair: LanguagePair,
        hud hudConfig: (appearsAfter: Duration, isModal: Bool)? = nil,
        timeout timeoutConfig: (duration: Duration, returnsInputs: Bool) = (.seconds(10), true)
    ) async -> Callback<Translation, Exception> {
        let getTranslationsResult = await getTranslations(
            [input],
            languagePair: languagePair,
            hud: hudConfig,
            timeout: timeoutConfig
        )

        switch getTranslationsResult {
        case let .success(translations):
            guard let translation = translations.first else {
                return .failure(.init(
                    metadata: .init(sender: self)
                ))
            }

            return .success(translation)

        case let .failure(exception):
            return .failure(exception)
        }
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

        let didComplete = LockIsolated(wrappedValue: false)
        let exception = LockIsolated<Exception?>(wrappedValue: nil)
        let translations = LockIsolated<[Translation]>(wrappedValue: [])

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
            let getTranslationsResult = await translator.getTranslations(
                inputs,
                languagePair: languagePair
            )

            timeout.cancel()

            switch getTranslationsResult {
            case let .success(_translations): translations.wrappedValue = _translations
            case let .failure(error):
                exception.wrappedValue = .init(
                    error,
                    metadata: .init(sender: self)
                )
            }

            return complete(timedOut: false)
        }
    }
}
