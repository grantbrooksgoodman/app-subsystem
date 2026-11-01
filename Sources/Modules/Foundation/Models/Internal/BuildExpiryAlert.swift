//
//  BuildExpiryAlert.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

/* Proprietary */
import AlertKit

@MainActor
final class BuildExpiryAlert {
    // MARK: - Constants Accessors

    private typealias Floats = FoundationConstants.CGFloats.BuildExpiryAlert

    // MARK: - Types

    fileprivate struct SessionStrings {
        let alertMessage: String
        let incorrectOverrideCodeHUDText: String
        let timeExpiredAlertMessage: String
        let timeExpiredAlertTitle: String
    }

    // MARK: - Dependencies

    @Dependency(\.alertKitConfig) private var alertKitConfig: AlertKit.Config
    @Dependency(\.build) private var build: Build
    @Dependency(\.coreKit) private var core: CoreKit
    @Dependency(\.uiApplication) private var uiApplication: UIApplication

    // MARK: - Properties

    static let shared = BuildExpiryAlert()

    private static let alertTitle = "End of Evaluation Period"
    private static let cancelButtonTitle = "Exit"
    private static let confirmButtonTitle = "Continue Use"
    private static let incorrectOverrideCodeHUDText = "Incorrect Override Code"
    private static let timeExpiredAlertMessage = "The application will now exit."
    private static let timeExpiredAlertTitle = "Time Expired"

    private let oldTranslationTimeoutConfig: AlertKit.TranslationTimeoutConfig

    private var countdownTask: Task<Void, Never>?
    private var presentationTask: Task<Void, Never>?
    private var remainingSeconds = Int(Floats.countdownSeconds)
    private var sessionStrings: SessionStrings?

    // MARK: - Computed Properties

    private var countdownString: String {
        String(
            format: "00:%02d",
            remainingSeconds
        )
    }

    private var englishAlertMessage: String { // swiftlint:disable:next line_length
        "The evaluation period for this pre-release build of \(build.codeName) has ended.\n\nTo continue using this version, enter the six-digit expiration override code associated with it.\n\nUntil updated to a newer build, entry of this code will be required each time the application is launched.\n\nTime remaining for successful entry:"
    }

    private var messageAttributes: AttributedStringConfig {
        .init(
            [.font: UIFont.systemFont(ofSize: Floats.primaryFontSize)],
            secondaryAttributes: [
                .init(
                    [
                        .font: UIFont.systemFont(ofSize: Floats.secondaryFontSize),
                        .foregroundColor: UIColor.red,
                    ],
                    stringRanges: [countdownString]
                ),
            ]
        )
    }

    // MARK: - Init

    private init() {
        oldTranslationTimeoutConfig = Dependency(\.alertKitConfig.translationTimeoutConfig).wrappedValue
    }

    // MARK: - Present / Dismiss

    func present() async {
        guard RootWindowStatus.shared.rootView != .forcedUpdateModalPage else { return }
        alertKitConfig.overrideTranslationTimeoutConfig(
            .init(
                .seconds(Int(Floats.translationTimeoutSeconds)),
                returnsInputsOnFailure: true
            )
        )

        let strings: SessionStrings
        if let sessionStrings {
            strings = sessionStrings
        } else {
            remainingSeconds = Int(Floats.countdownSeconds)
            strings = await translatedStrings()
            sessionStrings = strings
        }

        await presentAlert(with: strings)
    }

    func dismiss(triggerBuildExpiryOverride: Bool = true) {
        countdownTask?.cancel()
        countdownTask = nil
        presentationTask?.cancel()
        presentationTask = nil
        sessionStrings = nil

        alertKitConfig.overrideTranslationTimeoutConfig(oldTranslationTimeoutConfig)
        guard triggerBuildExpiryOverride else { return }
        RootWindowStatus.shared.buildExpiryOverrideTriggered = true
    }
}

private extension BuildExpiryAlert {
    // MARK: - Alert Presentation

    func presentAlert(with strings: SessionStrings) async {
        let overrideCode = build.expirationOverrideCode
        let textInputAlert = AKTextInputAlert(
            title: Self.alertTitle,
            message: displayedMessage(for: strings),
            attributes: .init(
                clearButtonMode: .never,
                isSecureTextEntry: true,
                keyboardType: .numberPad,
                placeholderText: "\(build.bundleVersion) | \(build.buildSKU)"
            ),
            cancelButtonTitle: Self.cancelButtonTitle,
            cancelButtonStyle: .destructive,
            confirmButtonTitle: Self.confirmButtonTitle
        )

        textInputAlert.setMessageAttributes(messageAttributes.alertKitMapping)
        textInputAlert.onTextFieldChange { textField in
            guard let text = textField?.text else { return }
            guard text.lowercasedTrimmingWhitespaceAndNewlines.count == overrideCode.count else {
                return textInputAlert.disableAction(at: 1)
            }

            textInputAlert.enableAction(at: 1)
        }

        presentationTask?.cancel()
        presentationTask = Task { @MainActor in
            await awaitAlertPresentation()
            guard !Task.isCancelled else { return }
            textInputAlert.disableAction(at: 1)
            startCountdown(with: strings)
        }

        let input = await textInputAlert.present(translating: [
            .cancelButtonTitle,
            .confirmButtonTitle,
            .title,
        ])

        presentationTask?.cancel()
        presentationTask = nil

        guard let input else { exit(0) }
        guard input.lowercasedTrimmingWhitespaceAndNewlines == overrideCode else {
            core.hud.flash(strings.incorrectOverrideCodeHUDText, image: .exclamation)
            Task.delayed(
                by: .seconds(Int(Floats.wrongCodeRetrySeconds))
            ) { await self.present() }

            return
        }

        dismiss()
    }

    func awaitAlertPresentation() async {
        while !uiApplication.isPresentingAlertController,
              !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(Int(Floats.presentationPollMilliseconds)))
        }
    }

    // MARK: - Countdown

    func startCountdown(with strings: SessionStrings) {
        guard countdownTask == nil else { return }
        countdownTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }

                remainingSeconds -= 1
                guard remainingSeconds >= 0 else {
                    return handleTimeExpiry(with: strings)
                }

                updatePresentedMessage(for: strings)
            }
        }
    }

    func handleTimeExpiry(with strings: SessionStrings) {
        countdownTask?.cancel()
        countdownTask = nil

        let alertController = UIAlertController(
            title: strings.timeExpiredAlertTitle,
            message: strings.timeExpiredAlertMessage,
            preferredStyle: .alert
        )

        uiApplication.dismissAlertControllers()
        core.ui.present(alertController)
        Task.delayed(by: .seconds(Int(Floats.exitDelaySeconds))) { exit(0) }
    }

    // MARK: - Message Composition

    func displayedMessage(for strings: SessionStrings) -> String {
        "\(strings.alertMessage)\n\(countdownString)"
    }

    func updatePresentedMessage(for strings: SessionStrings) {
        guard let alertController = uiApplication.keyViewController as? UIAlertController,
              alertController.textFields?.isEmpty == false else { return }

        let message = displayedMessage(for: strings)
        let key = AlertKit.Constants.uiAlertControllerAttributedMessageKeyName

        guard alertController.responds(
            to: NSSelectorFromString(
                "set\(key.prefix(1).uppercased())\(key.dropFirst()):"
            )
        ) else {
            return alertController.message = message
        }

        alertController.setValue(
            message.attributed(messageAttributes),
            forKey: key
        )
    }

    // MARK: - Translation

    func translatedStrings() async -> SessionStrings {
        let englishStrings = SessionStrings(
            alertMessage: englishAlertMessage,
            incorrectOverrideCodeHUDText: Self.incorrectOverrideCodeHUDText,
            timeExpiredAlertMessage: Self.timeExpiredAlertMessage,
            timeExpiredAlertTitle: Self.timeExpiredAlertTitle
        )

        guard let translationDelegate = alertKitConfig.translationDelegate else {
            return englishStrings
        }

        do {
            let translations = try await translationDelegate.getTranslations(
                [
                    .init(englishStrings.alertMessage),
                    .init(englishStrings.incorrectOverrideCodeHUDText),
                    .init(englishStrings.timeExpiredAlertMessage),
                    .init(englishStrings.timeExpiredAlertTitle),
                ],
                languagePair: .system,
                hud: alertKitConfig.translationHUDConfig,
                timeout: alertKitConfig.translationTimeoutConfig
            )

            func output(for input: String) -> String {
                translations.first(where: { $0.input.value == input })?.output ?? input
            }

            return .init(
                alertMessage: output(for: englishStrings.alertMessage),
                incorrectOverrideCodeHUDText: output(for: englishStrings.incorrectOverrideCodeHUDText),
                timeExpiredAlertMessage: output(for: englishStrings.timeExpiredAlertMessage),
                timeExpiredAlertTitle: output(for: englishStrings.timeExpiredAlertTitle)
            )
        } catch {
            Logger.log(
                .init(error, metadata: .init(sender: self)),
                domain: .translation
            )

            return englishStrings
        }
    }
}
