//
//  SubsystemStringKey.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

enum SubsystemStringKey: String, LocalizedStringKeyRepresentable {
    // MARK: - Cases

    case cancel
    case dismiss
    case done
    case errorReported
    case internetConnectionOffline
    case noEmail
    case noInternetMessage
    case reportBug
    case reportSent
    case sendFeedback
    case settings
    case somethingWentWrong
    case tapToReport
    case timedOut
    case tryAgain
    case yesterday

    // MARK: - Properties

    var referent: String { rawValue.snakeCased }
}
