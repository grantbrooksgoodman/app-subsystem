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
        @Dependency(\.coreKit) var core: CoreKit
        @Dependency(\.translationService) var translator: TranslationService

        let didComplete = LockIsolated(wrappedValue: false)
        let translations = LockIsolated<[Translation]>(wrappedValue: [])
        let exception = LockIsolated<Exception?>(wrappedValue: nil)

        if let hudConfig {
            Task.delayed(by: hudConfig.appearsAfter) { @MainActor in
                guard !didComplete.wrappedValue else { return }
                core.hud.showProgress(isModal: hudConfig.isModal)
            }
        }

        func canComplete() -> Bool {
            didComplete.projectedValue.withValue {
                guard !$0 else { return false }
                $0 = true
                return true
            }
        }

        func complete(timedOut: Bool) {
            guard canComplete() else { return }

            if hudConfig != nil {
                Task { @MainActor in
                    @Dependency(\.coreKit) var core: CoreKit
                    core.hud.hide()
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
                let missing = inputs.filter { input in
                    !existingTranslations.map(\.input).contains(input)
                }
                let fallbacks = missing.map { input in
                    Translation(
                        input: input,
                        output: input.original.sanitized,
                        languagePair: languagePair
                    )
                }
                existingTranslations.append(contentsOf: fallbacks)
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
