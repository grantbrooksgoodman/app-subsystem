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

final class BuildExpiryAlert {
    // MARK: - Properties

    // String
    private static var expiryAlertMessage = ""
    private static var incorrectOverrideCodeHUDText = "Incorrect Override Code"
    private static var timeExpiredAlertMessage = "The application will now exit."
    private static var timeExpiredAlertTitle = "Time Expired"

    // Other
    private static var exitTimer: Timer?
    private static var remainingSeconds = 30

    // MARK: - Computed Properties

    private static var messageAttributes: AttributedStringConfig {
        let messageComponents = expiryAlertMessage.components(separatedBy: ":")
        let attributeRange = messageComponents[1 ... messageComponents.count - 1].joined(separator: ":")
        return .init(
            [.font: UIFont.systemFont(ofSize: 13)],
            secondaryAttributes: [
                .init(
                    [.font: UIFont.systemFont(ofSize: 17), .foregroundColor: UIColor.red],
                    stringRanges: [attributeRange]
                ),
            ]
        )
    }

    // MARK: - Init

    private init() {}

    // MARK: - Present

    @MainActor
    static func present() async {
        @Dependency(\.alertKitConfig) var alertKitConfig: AlertKit.Config
        @Dependency(\.build) var build: Build
        @Dependency(\.coreKit) var core: CoreKit

        let oldTranslationTimeoutConfig = alertKitConfig.translationTimeoutConfig
        alertKitConfig.overrideTranslationTimeoutConfig(
            .init(.seconds(60), returnsInputsOnFailure: true)
        )

        if expiryAlertMessage.isEmpty { // swiftlint:disable:next line_length
            expiryAlertMessage = "The evaluation period for this pre-release build of \(build.codeName) has ended.\n\nTo continue using this version, enter the six-digit expiration override code associated with it.\n\nUntil updated to a newer build, entry of this code will be required each time the application is launched.\n\nTime remaining for successful entry:\n00:30"
        }

        guard let translationDelegate = alertKitConfig.translationDelegate else { return }
        let getTranslationsResult = await translationDelegate.getTranslations(
            [
                .init(expiryAlertMessage),
                .init(incorrectOverrideCodeHUDText),
                .init(timeExpiredAlertMessage),
                .init(timeExpiredAlertTitle),
            ],
            languagePair: .system,
            hud: alertKitConfig.translationHUDConfig,
            timeout: alertKitConfig.translationTimeoutConfig
        )

        switch getTranslationsResult {
        case let .success(translations):
            expiryAlertMessage = translations.first(where: { $0.input.value == expiryAlertMessage })?.output ?? expiryAlertMessage
            incorrectOverrideCodeHUDText = translations.first(where: { $0.input.value == incorrectOverrideCodeHUDText })?.output ?? incorrectOverrideCodeHUDText
            timeExpiredAlertMessage = translations.first(where: { $0.input.value == timeExpiredAlertMessage })?.output ?? timeExpiredAlertMessage
            timeExpiredAlertTitle = translations.first(where: { $0.input.value == timeExpiredAlertTitle })?.output ?? timeExpiredAlertTitle
            await presentAlert()

        case let .failure(error):
            Logger.log(.init(error, metadata: [self, #file, #function, #line]), domain: .translation)
            await presentAlert()
        }

        func presentAlert() async {
            let textInputAlert = AKTextInputAlert(
                title: "End of Evaluation Period",
                message: expiryAlertMessage,
                attributes: .init(
                    clearButtonMode: .never,
                    isSecureTextEntry: true,
                    keyboardType: .numberPad,
                    placeholderText: "\(build.bundleVersion) | \(build.buildSKU)"
                ),
                cancelButtonTitle: "Exit",
                cancelButtonStyle: .destructive,
                confirmButtonTitle: "Continue Use"
            )

            textInputAlert.setMessageAttributes(messageAttributes.alertKitMapping)
            textInputAlert.onTextFieldChange { textField in
                if let text = textField?.text {
                    guard text.lowercasedTrimmingWhitespaceAndNewlines.count == 6 else { return textInputAlert.disableAction(at: 1) }
                    textInputAlert.enableAction(at: 1)
                }
            }

            @MainActor
            func disableAction() {
                @Dependency(\.uiApplication) var uiApplication: UIApplication
                guard uiApplication.isPresentingAlertController else {
                    return core.gcd.after(.milliseconds(100)) { disableAction() }
                }

                textInputAlert.disableAction(at: 1)
            }

            disableAction()
            setTimer()

            let input = await textInputAlert.present(translating: [
                .cancelButtonTitle,
                .confirmButtonTitle,
                .title,
            ])

            guard let input else { exit(0) }
            guard input == build.expirationOverrideCode else {
                core.hud.flash(incorrectOverrideCodeHUDText, image: .exclamation)
                _ = Task.delayed(by: .seconds(2)) { await self.present() }
                return
            }

            exitTimer?.invalidate()
            exitTimer = nil

            alertKitConfig.overrideTranslationTimeoutConfig(oldTranslationTimeoutConfig)
            RootWindowStatus.shared.buildExpiryOverrideTriggered = true
        }
    }

    // MARK: - Auxiliary

    @objc
    private static func decrementSecond() {
        @Dependency(\.coreKit) var core: CoreKit
        @Dependency(\.uiApplication) var uiApplication: UIApplication

        remainingSeconds -= 1

        guard remainingSeconds < 0 else {
            let decrementString = String(format: "%02d", remainingSeconds)
            expiryAlertMessage = "\(expiryAlertMessage.components(separatedBy: ":")[0]):\n00:\(decrementString)"
            (uiApplication.keyViewController as? UIAlertController)?.setValue(
                expiryAlertMessage.attributed(messageAttributes),
                forKey: "attributedMessage"
            )
            return
        }

        exitTimer?.invalidate()
        exitTimer = nil

        let alertController = UIAlertController(
            title: timeExpiredAlertTitle,
            message: timeExpiredAlertMessage,
            preferredStyle: .alert
        )

        uiApplication.dismissAlertControllers()
        core.ui.present(alertController)
        core.gcd.after(.seconds(5)) { fatalError("Evaluation period ended") }
    }

    private static func setTimer() {
        @Dependency(\.coreKit.gcd) var coreGCD: CoreKit.GCD
        @Dependency(\.uiApplication) var uiApplication: UIApplication

        guard uiApplication.isPresentingAlertController else {
            return coreGCD.after(.milliseconds(100)) { setTimer() }
        }

        guard let exitTimer = exitTimer,
              exitTimer.isValid else {
            self.exitTimer = .scheduledTimer(
                timeInterval: 1,
                target: self,
                selector: #selector(decrementSecond),
                userInfo: nil,
                repeats: true
            )
            return
        }
    }
}
