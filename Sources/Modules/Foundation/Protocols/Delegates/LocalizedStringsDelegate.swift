//
//  LocalizedStringsDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension AppSubsystem.Delegates {
    protocol LocalizedStringsDelegate {
        var cancel: String { get }
        var dismiss: String { get }
        var done: String { get }
        var internetConnectionOffline: String { get }
        var noEmail: String { get }
        var noInternetMessage: String { get }
        var reportBug: String { get }
        var reportSent: String { get }
        var sendFeedback: String { get }
        var settings: String { get }
        var somethingWentWrong: String { get }
        var tapToReport: String { get }
        var timedOut: String { get }
        var tryAgain: String { get }
        var yesterday: String { get }
    }

    struct DefaultLocalizedStringsDelegate: AppSubsystem.Delegates.LocalizedStringsDelegate {
        public let cancel = DefaultLocalizedStringsDelegate.cancelString
        public let dismiss = DefaultLocalizedStringsDelegate.dismissString
        public let done = DefaultLocalizedStringsDelegate.doneString
        public let internetConnectionOffline = DefaultLocalizedStringsDelegate.internetConnectionOfflineString
        public let noEmail = DefaultLocalizedStringsDelegate.noEmailString
        public let noInternetMessage = DefaultLocalizedStringsDelegate.noInternetMessageString
        public let reportBug = DefaultLocalizedStringsDelegate.reportBugString
        public let reportSent = DefaultLocalizedStringsDelegate.reportSentString
        public let sendFeedback = DefaultLocalizedStringsDelegate.sendFeedbackString
        public let settings = DefaultLocalizedStringsDelegate.settingsString
        public let somethingWentWrong = DefaultLocalizedStringsDelegate.somethingWentWrongString
        public let tapToReport = DefaultLocalizedStringsDelegate.tapToReportString
        public let timedOut = DefaultLocalizedStringsDelegate.timedOutString
        public let tryAgain = DefaultLocalizedStringsDelegate.tryAgainString
        public let yesterday = DefaultLocalizedStringsDelegate.yesterdayString
    }
}
