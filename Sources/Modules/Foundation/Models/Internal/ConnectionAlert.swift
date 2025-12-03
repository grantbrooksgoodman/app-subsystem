//
//  ConnectionAlert.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

/* Proprietary */
import AlertKit

enum ConnectionAlert {
    // MARK: - Present

    @MainActor
    static func present() async {
        @Dependency(\.build) var build: Build
        @Dependency(\.uiApplication) var uiApplication: UIApplication

        var actions: [AKAction] = [.cancelAction(title: "OK")]
        if let settingsURL = URL(string: massageRedirectionKey("oddUdfstgb")),
           uiApplication.canOpenURL(settingsURL) {
            let settingsAction: AKAction = .init(AppSubsystem.delegates.localizedStrings.settings) { uiApplication.open(settingsURL) }
            actions.append(settingsAction)
        }

        await AKAlert(
            message: AppSubsystem.delegates.localizedStrings.noInternetMessage,
            actions: actions
        ).present(translating: [])
    }

    // MARK: - Auxiliary

    private static func massageRedirectionKey(_ string: String) -> String {
        var lowercasedString = string.lowercased().ciphered(by: 12)
        lowercasedString = lowercasedString.replacingOccurrences(of: "g", with: "-")
        lowercasedString = lowercasedString.replacingOccurrences(of: "n", with: ":")

        var capitalizedCharacters = [String]()
        for (index, character) in lowercasedString.components.enumerated() {
            let finalCharacter = (index == 0 || index == 4) ? character.uppercased() : character
            capitalizedCharacters.append(finalCharacter)
        }

        return capitalizedCharacters.joined()
    }
}
