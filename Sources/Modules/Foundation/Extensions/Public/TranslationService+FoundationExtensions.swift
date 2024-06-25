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
        return await withCheckedContinuation { continuation in
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

    func resolve(_ strings: TranslatedLabelStrings.Type) async -> Callback<[TranslationOutputMap], Exception> {
        let getTranslationsResult = await getTranslations(strings.keyPairs.map(\.input), languagePair: .system)

        switch getTranslationsResult {
        case let .success(translations):
            let outputs = strings.keyPairs.reduce(into: [TranslationOutputMap]()) { partialResult, keyPair in
                if let translation = translations.first(where: { $0.input.value == keyPair.input.value }) {
                    partialResult.append(.init(key: keyPair.key, value: translation.output))
                } else {
                    partialResult.append(keyPair.defaultOutputMap)
                }
            }
            return .success(outputs)

        case let .failure(error):
            return .failure(.init(error, metadata: [self, #file, #function, #line]))
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
            guard let translation = translations.first else { return .failure(.init(metadata: [self, #file, #function, #line])) }
            return .success(translation)

        case let .failure(exception):
            return .failure(exception)
        }
    }

    private func getTranslations(
        _ inputs: [TranslationInput],
        languagePair: LanguagePair,
        hud hudConfig: (appearsAfter: Duration, isModal: Bool)? = nil,
        timeout timeoutConfig: (duration: Duration, returnsInputs: Bool) = (.seconds(10), true),
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

        var exceptions = [Exception]()
        var translations = [Translation]()

        func handleExceptionAndComplete() {
            let exception = exceptions.compiledException ?? .init(metadata: [self, #file, #function, #line])
            guard timeoutConfig.returnsInputs else { return completion(.failure(exception)) }

            Logger.log(exception, domain: .translation)
            return completion(.success(translations))
        }

        func handleTimeout() {
            guard canComplete else { return }
            translations.append(contentsOf: inputs.filter { !translations.map(\.input).contains($0) }.map {
                Translation(
                    input: $0,
                    output: $0.original.sanitized,
                    languagePair: languagePair
                )
            })

            guard exceptions.isEmpty else { return }
            guard translations.count == inputs.count else {
                return completion(.failure(.init(
                    "Mismatched ratio returned.",
                    metadata: [self, #file, #function, #line]
                )))
            }

            guard timeoutConfig.returnsInputs else { return completion(.failure(.timedOut([self, #file, #function, #line]))) }
            Logger.log(.timedOut([self, #file, #function, #line]), domain: .translation)
            completion(.success(translations))
        }

        var timeout = Timeout(after: timeoutConfig.duration) { handleTimeout() }

        Task {
            for input in inputs {
                let translateResult = await translator.translate(
                    input,
                    languagePair: languagePair
                )

                timeout.cancel()
                timeout = .init(after: timeoutConfig.duration) { handleTimeout() }

                switch translateResult {
                case let .success(translation):
                    translations.append(translation)

                case let .failure(error):
                    exceptions.append(.init(error, metadata: [self, #file, #function, #line]))
                }
            }

            guard canComplete else { return }
            guard exceptions.isEmpty else { return handleExceptionAndComplete() }
            guard translations.count == inputs.count else {
                return completion(.failure(.init(
                    "Mismatched ratio returned.",
                    metadata: [self, #file, #function, #line]
                )))
            }

            completion(.success(translations))
        }
    }
}
