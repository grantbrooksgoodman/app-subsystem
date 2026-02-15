//
//  TranslationService+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import Translator
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
        completion: @escaping (Callback<[Translation], Exception>) -> Void
    ) {
        @Dependency(\.coreKit) var core: CoreKit
        @Dependency(\.translationService) var translator: TranslationService
        var didComplete = false

        if let hudConfig {
            core.gcd.after(hudConfig.appearsAfter) {
                guard !didComplete else { return }
                core.hud.showProgress(isModal: hudConfig.isModal)
            }
        }

        var canComplete: Bool {
            guard !didComplete else { return false }
            didComplete = true
            guard hudConfig != nil else { return true }
            core.hud.hide()
            return true
        }

        var exception: Exception?
        var translations = [Translation]()

        func complete(timedOut: Bool) {
            guard canComplete else { return }

            if let exception {
                guard timeoutConfig.returnsInputs else {
                    return completion(.failure(exception))
                }

                Logger.log(
                    exception,
                    domain: .translation
                )

                return completion(.success(translations))
            }

            guard translations.count == inputs.count else {
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

            return completion(.success(translations))
        }

        let timeout = Timeout(after: timeoutConfig.duration) {
            translations.append(contentsOf: inputs
                .filter { !translations.map(\.input).contains($0) }
                .map {
                    Translation(
                        input: $0,
                        output: $0.original.sanitized,
                        languagePair: languagePair
                    )
                }
            )

            return complete(timedOut: true)
        }

        Task {
            let getTranslationsResult = await translator.getTranslations(
                inputs,
                languagePair: languagePair
            )

            timeout.cancel()

            switch getTranslationsResult {
            case let .success(_translations): translations = _translations
            case let .failure(error):
                exception = .init(
                    error,
                    metadata: .init(sender: self)
                )
            }

            return complete(timedOut: false)
        }
    }
}
