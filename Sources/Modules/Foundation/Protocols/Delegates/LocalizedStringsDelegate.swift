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
        public var cancel: String { DefaultLocalizedStringsDelegate.cancelString }
        public var dismiss: String { DefaultLocalizedStringsDelegate.dismissString }
        public var done: String { DefaultLocalizedStringsDelegate.doneString }
        public var internetConnectionOffline: String { DefaultLocalizedStringsDelegate.internetConnectionOfflineString }
        public var noEmail: String { DefaultLocalizedStringsDelegate.noEmailString }
        public var noInternetMessage: String { DefaultLocalizedStringsDelegate.noInternetMessageString }
        public var reportBug: String { DefaultLocalizedStringsDelegate.reportBugString }
        public var reportSent: String { DefaultLocalizedStringsDelegate.reportSentString }
        public var sendFeedback: String { DefaultLocalizedStringsDelegate.sendFeedbackString }
        public var settings: String { DefaultLocalizedStringsDelegate.settingsString }
        public var somethingWentWrong: String { DefaultLocalizedStringsDelegate.somethingWentWrongString }
        public var tapToReport: String { DefaultLocalizedStringsDelegate.tapToReportString }
        public var timedOut: String { DefaultLocalizedStringsDelegate.timedOutString }
        public var tryAgain: String { DefaultLocalizedStringsDelegate.tryAgainString }
        public var yesterday: String { DefaultLocalizedStringsDelegate.yesterdayString }
    }
}
