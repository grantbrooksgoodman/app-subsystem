//
//  LocalizedStringsDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension AppSubsystem.Delegates {
    /// A type that provides localized strings used by the subsystem's
    /// built-in UI components.
    ///
    /// The subsystem references these strings for button titles, error
    /// messages, and other user-facing text that appears in alerts,
    /// toasts, and system views. Conform to this protocol to supply
    /// translations that match the user's current language:
    ///
    /// ```swift
    /// struct AppLocalizedStrings: AppSubsystem.Delegates.LocalizedStringsDelegate {
    ///     var cancel: String { Localized(.cancel).wrappedValue }
    ///     var dismiss: String { Localized(.dismiss).wrappedValue }
    ///     // ...
    /// }
    /// ```
    ///
    /// If you do not provide a custom conformance, the subsystem uses
    /// ``DefaultLocalizedStringsDelegate``, which returns English
    /// strings for every property.
    protocol LocalizedStringsDelegate {
        /// The localized title for a cancel action.
        var cancel: String { get }

        /// The localized title for a dismiss action.
        var dismiss: String { get }

        /// The localized title for a done action.
        var done: String { get }

        /// The localized message indicating that an error has been
        /// reported.
        var errorReported: String { get }

        /// The localized message indicating that the internet
        /// connection is offline.
        var internetConnectionOffline: String { get }

        /// The localized message shown when no e-mail account is
        /// configured on the device.
        var noEmail: String { get }

        /// The localized body text for a no-internet-connection
        /// alert.
        var noInternetMessage: String { get }

        /// The localized title for a bug reporting action.
        var reportBug: String { get }

        /// The localized message confirming that a report has been
        /// sent.
        var reportSent: String { get }

        /// The localized title for a send feedback action.
        var sendFeedback: String { get }

        /// The localized title for a settings action.
        var settings: String { get }

        /// The localized fallback message for an unexpected error.
        var somethingWentWrong: String { get }

        /// The localized message prompting the user to tap to report
        /// an error.
        var tapToReport: String { get }

        /// The localized message indicating that an operation timed
        /// out.
        var timedOut: String { get }

        /// The localized title for a try again action.
        var tryAgain: String { get }

        /// The localized word for "yesterday."
        var yesterday: String { get }
    }

    /// The default localized strings delegate, which returns English
    /// strings for every property.
    struct DefaultLocalizedStringsDelegate: AppSubsystem.Delegates.LocalizedStringsDelegate {
        public let cancel = DefaultLocalizedStringsDelegate.cancelString
        public let dismiss = DefaultLocalizedStringsDelegate.dismissString
        public let done = DefaultLocalizedStringsDelegate.doneString
        public let errorReported = DefaultLocalizedStringsDelegate.errorReportedString
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
