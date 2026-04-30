//
//  Logger.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

// swiftlint:disable file_length type_body_length

/* Native */
import Foundation
import os

/* Proprietary */
import AlertKit
import Translator

/// A centralized, thread-safe logging service that writes structured diagnostic
/// output to the console and to an on-disk session record.
///
/// Use `Logger` to record messages and exceptions during development
/// and in prerelease builds. Each log entry is tagged with a
/// ``LoggerDomain``, a timestamp, and the caller's file, function,
/// and line number, making it straightforward to trace issues back to
/// their origin.
///
/// ## Logging Messages and Exceptions
///
/// Log a plain-text message by passing a string and the calling
/// context:
///
/// ```swift
/// Logger.log(
///     "Sync completed successfully",
///     domain: .networking,
///     sender: self
/// )
/// ```
///
/// Log an exception directly to capture its error code, descriptor,
/// and any attached user info:
///
/// ```swift
/// Logger.log(
///     exception,
///     domain: .persistence
/// )
/// ```
///
/// Both overloads accept an optional ``AlertType`` to display an
/// alert or toast alongside the log entry.
///
/// ## Runtime Warnings
///
/// Pass `true` for the `showRuntimeWarning` parameter on any `log`
/// method to surface the entry as a runtime issue in Xcode.
///
/// Runtime issues appear in the issue navigator alongside compiler
/// warnings and errors, making them useful for flagging conditions
/// that merit attention during development.
///
/// ```swift
/// Logger.log(
///     "Unexpected nil value for user ID",
///     domain: .general,
///     showRuntimeWarning: true,
///     sender: self
/// )
/// ```
///
/// Runtime issues are not visible when the `OS_ACTIVITY_MODE`
/// environment variable is set to `disable`.
///
/// ## Domain Subscription
///
/// The logger only produces output for domains it is subscribed to.
/// Subscribe or unsubscribe at runtime:
///
/// ```swift
/// Logger.subscribe(to: .networking)
/// Logger.unsubscribe(from: .translation)
/// ```
///
/// To configure the initial set of subscribed domains at launch,
/// provide a ``AppSubsystem/Delegates/LoggerDomainSubscriptionDelegate``
/// conformance.
///
/// ## Filtering
///
/// Apply a ``Filter`` to narrow log output – for example, to see
/// only exceptions or to restrict output to specific source files.
/// Filters affect both console output and the session record.
///
/// ## Streaming
///
/// For operations that produce many related log entries in rapid
/// succession, open a stream to group the output under a single
/// header. Call ``openStream(message:domain:sender:fileName:function:line:)``
/// to begin, ``logToStream(_:domain:line:)`` for each entry, and
/// ``closeStream(message:domain:onLine:)`` to end the group.
///
/// ## Session Record
///
/// Every log entry is appended to an on-disk file for the current
/// session, accessible via ``sessionRecordFilePath``. Domains listed
/// in ``domainsExcludedFromSessionRecord`` are omitted from this
/// file. The session record is stored in the temporary directory and
/// is not persisted across launches.
///
/// - SeeAlso: ``LoggerDomain``, ``Exception``
public enum Logger {
    // MARK: - Types

    /// The kind of user-visible alert to present alongside a log
    /// entry.
    ///
    /// When you pass an `AlertType` to one of the `log` methods, the
    /// logger displays the corresponding alert after recording the
    /// entry. Use ``errorAlert`` for reportable exceptions,
    /// ``normalAlert`` for informational messages, or ``toast`` for
    /// lightweight, non-blocking feedback.
    public enum AlertType: Sendable {
        /* MARK: Cases */

        /// An error alert that offers to file a report when the
        /// exception is reportable.
        case errorAlert

        /// A standard informational alert.
        case normalAlert

        /// A toast notification.
        ///
        /// - Parameters:
        ///   - style: The visual style of the toast. Pass `nil` to
        ///     infer the style from the log entry.
        ///   - isPersistent: Whether the toast remains on screen
        ///     until manually dismissed. The default is `true`.
        case toast(
            style: Toast.Style?,
            isPersistent: Bool = true
        )

        /* MARK: Properties */

        /// A toast notification with the default style and persistent
        /// display.
        public static let toast: AlertType = .toast(style: nil)

        /* MARK: Computed Properties */

        /// A toast notification that is only shown in prerelease
        /// builds.
        ///
        /// Returns `nil` when the current build milestone is
        /// ``Build/Milestone/generalRelease``, effectively silencing
        /// the alert in production.
        public static var toastInPrerelease: AlertType? {
            @Dependency(\.build.milestone) var buildMilestone: Build.Milestone
            guard buildMilestone != .generalRelease else { return nil }
            return .toast
        }

        /* MARK: Methods */

        /// Returns a toast notification with the given style, or
        /// `nil` in general-release builds.
        ///
        /// - Parameters:
        ///   - style: The visual style of the toast. Pass `nil` to
        ///     infer the style.
        ///   - isPersistent: Whether the toast remains on screen
        ///     until manually dismissed. The default is `true`.
        ///
        /// - Returns: An ``AlertType`` in prerelease builds, or `nil`
        ///   in general-release builds.
        public static func toastInPrerelease(
            style: Toast.Style?,
            isPersistent: Bool = true
        ) -> AlertType? {
            @Dependency(\.build.milestone) var buildMilestone: Build.Milestone
            guard buildMilestone != .generalRelease else { return nil }
            return .toast(
                style: style,
                isPersistent: isPersistent
            )
        }
    }

    /// A rule that restricts which log entries are recorded.
    ///
    /// Apply a filter with ``setFilter(_:)`` to narrow the logger's
    /// output. Only entries that satisfy the active filter are printed
    /// to the console and written to the session record.
    public enum Filter: Equatable {
        /* MARK: Cases */

        /// Restricts output to entries originating from the specified
        /// source files.
        case byFileNames(_ fileNames: Set<String>)

        /// Restricts output to exception entries only, ignoring
        /// plain-text messages.
        case exceptionsOnly

        /// Restricts output to reportable exception entries only.
        case reportableExceptionsOnly

        /* MARK: Properties */

        fileprivate var fileNames: Set<String>? {
            switch self {
            case let .byFileNames(fileNames): fileNames
            default: nil
            }
        }
    }

    // MARK: - Properties

    private static let currentTimeLastCalled = LockIsolated<Date>(.now)
    private static let ioLock = NSRecursiveLock()
    private static let sessionID = UUID()
    private static let streamOpen = LockIsolated<Bool>(false)
    private static let utf8BOM = Data([0xEF, 0xBB, 0xBF])
    private static let _domainsExcludedFromSessionRecord = LockIsolated<[LoggerDomain]>([])
    private static let _filter = LockIsolated<Filter?>(nil)
    private static let _reportsErrorsAutomatically = LockIsolated<Bool>(false)
    private static let _subscribedDomains = LockIsolated<[LoggerDomain]>([])

    // MARK: - Computed Properties

    /// The domains whose output is excluded from the on-disk session
    /// record.
    ///
    /// Messages logged to these domains still appear in the console
    /// but are not written to the session record file.
    public static var domainsExcludedFromSessionRecord: [LoggerDomain] {
        _domainsExcludedFromSessionRecord.wrappedValue
    }

    /// The currently active filter, or `nil` if no filter is applied.
    public static var filter: Filter? {
        _filter.wrappedValue
    }

    /// A Boolean value that indicates whether reportable exceptions
    /// are filed automatically.
    ///
    /// When `true`, the logger forwards reportable exceptions to the
    /// configured report delegate immediately after logging, without
    /// requiring user interaction.
    public static var reportsErrorsAutomatically: Bool {
        _reportsErrorsAutomatically.wrappedValue
    }

    /// The file URL of the on-disk session record for the current
    /// launch.
    ///
    /// The session record is a UTF-8 text file stored in the
    /// temporary directory. A new file is created for each launch and
    /// is not persisted across sessions.
    public static var sessionRecordFilePath: URL {
        @Dependency(\.fileManager) var fileManager: FileManager
        return fileManager.temporaryDirectory.appending(path: "\(sessionID.uuidString).txt")
    }

    /// The domains the logger is currently subscribed to.
    ///
    /// Only messages logged to a subscribed domain produce output.
    public static var subscribedDomains: [LoggerDomain] {
        _subscribedDomains.wrappedValue
    }

    @usableFromInline
    static let swiftUIDynamicSharedObject = LockIsolated<UnsafeRawPointer?>(
        {
            // Walk loaded images looking for SwiftUI
            for index in 0 ..< _dyld_image_count() {
                if let imageName = _dyld_get_image_name(index) {
                    let imagePath = String(cString: imageName)
                    if imagePath.hasSuffix("/SwiftUI") ||
                        imagePath.contains("/SwiftUI.framework/") {
                        return UnsafeRawPointer(_dyld_get_image_header(index))
                    }
                }
            }
            return nil
        }()
    )

    private static var elapsedTime: String {
        let time = String(abs(currentTimeLastCalled.wrappedValue.seconds(from: Date.now)))
        return time == "0" ? "" : " @ \(time)s FLC"
    }

    // MARK: - Domain Subscription

    /// Subscribes the logger to the given domain.
    ///
    /// After subscribing, messages logged to this domain appear in
    /// the console and are written to the session record. Subscribing
    /// to a domain that is already subscribed has no effect.
    ///
    /// - Parameter domain: The domain to subscribe to.
    public static func subscribe(to domain: LoggerDomain) {
        _subscribedDomains.projectedValue.withValue {
            $0.append(domain)
            $0 = $0.unique
        }
    }

    /// Subscribes the logger to each of the given domains.
    ///
    /// - Parameter domains: The domains to subscribe to.
    public static func subscribe(to domains: [LoggerDomain]) {
        domains.forEach { subscribe(to: $0) }
    }

    /// Unsubscribes the logger from the given domain.
    ///
    /// After unsubscribing, messages logged to this domain are
    /// silently ignored. Unsubscribing from a domain that is not
    /// currently subscribed has no effect.
    ///
    /// - Parameter domain: The domain to unsubscribe from.
    public static func unsubscribe(from domain: LoggerDomain) {
        _subscribedDomains.projectedValue.withValue {
            $0 = $0.filter { $0 != domain }
        }
    }

    /// Unsubscribes the logger from each of the given domains.
    ///
    /// - Parameter domains: The domains to unsubscribe from.
    public static func unsubscribe(from domains: [LoggerDomain]) {
        domains.forEach { unsubscribe(from: $0) }
    }

    // MARK: - Setters

    /// Sets the domains whose output is excluded from the on-disk
    /// session record.
    ///
    /// - Parameter domainsExcludedFromSessionRecord: The domains to
    ///   exclude.
    public static func setDomainsExcludedFromSessionRecord(_ domainsExcludedFromSessionRecord: [LoggerDomain]) {
        _domainsExcludedFromSessionRecord.wrappedValue = domainsExcludedFromSessionRecord
    }

    /// Sets the active log filter.
    ///
    /// Pass `nil` to remove any existing filter and allow all
    /// entries through.
    ///
    /// - Parameter filter: The filter to apply, or `nil` to clear
    ///   the current filter.
    public static func setFilter(_ filter: Filter?) {
        _filter.wrappedValue = filter
    }

    /// Sets whether reportable exceptions are filed automatically.
    ///
    /// When enabled, the logger forwards reportable exceptions to
    /// the configured report delegate immediately after logging,
    /// without presenting a prompt to the user.
    ///
    /// - Parameter reportsErrorsAutomatically: A Boolean value that
    ///   indicates whether automatic reporting is enabled.
    public static func setReportsErrorsAutomatically(_ reportsErrorsAutomatically: Bool) {
        _reportsErrorsAutomatically.wrappedValue = reportsErrorsAutomatically
    }

    // MARK: - Logging

    /// Logs an `Error` value.
    ///
    /// The error is wrapped in an ``Exception`` using the provided
    /// metadata before being recorded. The resulting log entry
    /// includes the exception's descriptor and error code.
    ///
    /// - Parameters:
    ///   - error: The error to log.
    ///   - domain: The domain to log to. The default is ``LoggerDomain/general``.
    ///   - alertType: An optional alert to present alongside the log
    ///     entry. The default is `nil`.
    ///   - showRuntimeWarning: A Boolean value that indicates
    ///     whether to surface the entry as a runtime issue in
    ///     Xcode. The default is `false`.
    ///   - metadata: The caller metadata for the log entry.
    @_transparent
    public static func log(
        _ error: Error,
        domain: LoggerDomain = .general,
        with alertType: AlertType? = .none,
        showRuntimeWarning: Bool = false,
        metadata: ExceptionMetadata
    ) {
        let exception = Exception(
            error,
            metadata: metadata
        )

        if _logException(
            exception,
            domain: domain,
            with: alertType
        ), showRuntimeWarning {
            _runtimeWarn(
                exception.descriptor,
                sender: metadata.sender
            )
        }
    }

    /// Logs an `NSError` value.
    ///
    /// The error is wrapped in an ``Exception`` using the provided
    /// metadata before being recorded. The resulting log entry
    /// includes the exception's descriptor and error code.
    ///
    /// - Parameters:
    ///   - error: The error to log.
    ///   - domain: The domain to log to. The default is ``LoggerDomain/general``.
    ///   - alertType: An optional alert to present alongside the log
    ///     entry. The default is `nil`.
    ///   - showRuntimeWarning: A Boolean value that indicates
    ///     whether to surface the entry as a runtime issue in
    ///     Xcode. The default is `false`.
    ///   - metadata: The caller metadata for the log entry.
    @_transparent
    public static func log(
        _ error: NSError,
        domain: LoggerDomain = .general,
        with alertType: AlertType? = .none,
        showRuntimeWarning: Bool = false,
        metadata: ExceptionMetadata
    ) {
        let exception = Exception(
            error,
            metadata: metadata
        )

        if _logException(
            exception,
            domain: domain,
            with: alertType
        ), showRuntimeWarning {
            _runtimeWarn(
                exception.descriptor,
                sender: metadata.sender
            )
        }
    }

    /// Logs an exception.
    ///
    /// The log entry includes the exception's descriptor, error code,
    /// user info (if any), source location, and a timestamp. When the
    /// exception is reportable and ``reportsErrorsAutomatically`` is
    /// enabled, the exception is also forwarded to the configured
    /// report delegate.
    ///
    /// - Parameters:
    ///   - exception: The exception to log.
    ///   - domain: The domain to log to. The default is ``LoggerDomain/general``.
    ///   - alertType: An optional alert to present alongside the log
    ///     entry. The default is `nil`.
    ///   - showRuntimeWarning: A Boolean value that indicates
    ///     whether to surface the entry as a runtime issue in
    ///     Xcode. The default is `false`.
    @_transparent
    public static func log(
        _ exception: Exception,
        domain: LoggerDomain = .general,
        with alertType: AlertType? = .none,
        showRuntimeWarning: Bool = false,
    ) {
        if _logException(
            exception,
            domain: domain,
            with: alertType
        ), showRuntimeWarning {
            _runtimeWarn(
                exception.descriptor,
                sender: exception.metadata.sender
            )
        }
    }

    /// Logs a plain-text message.
    ///
    /// Use this overload for diagnostic messages that are not
    /// associated with an exception. The log entry includes the
    /// caller's file, function, and line number alongside the
    /// message text.
    ///
    /// - Parameters:
    ///   - text: The message to log.
    ///   - domain: The domain to log to. The default is ``LoggerDomain/general``.
    ///   - alertType: An optional alert to present alongside the log
    ///     entry. The default is `nil`.
    ///   - showRuntimeWarning: A Boolean value that indicates
    ///     whether to surface the entry as a runtime issue in
    ///     Xcode. The default is `false`.
    ///   - sender: The object or type that initiated the log call,
    ///     used to identify the caller in the log header.
    ///   - fileName: The source file. The default is the caller's
    ///     file.
    ///   - function: The calling function. The default is the
    ///     caller's function.
    ///   - line: The source line number. The default is the caller's
    ///     line.
    @_transparent
    public static func log(
        _ text: String,
        domain: LoggerDomain = .general,
        with alertType: AlertType? = .none,
        showRuntimeWarning: Bool = false,
        sender: Any,
        fileName: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        let metadata = ExceptionMetadata(
            sender: sender,
            fileName: fileName,
            function: function,
            line: line
        )

        if _logText(
            text,
            domain: domain,
            with: alertType,
            metadata: metadata
        ), showRuntimeWarning {
            _runtimeWarn(
                text,
                sender: metadata.sender
            )
        }
    }

    // MARK: - Internal Logging

    @usableFromInline
    @discardableResult
    static func _logException(
        _ exception: Exception,
        domain: LoggerDomain,
        with alertType: AlertType?
    ) -> Bool {
        @Dependency(\.loggerDateFormatter) var dateFormatter: DateFormatter

        func showAlertIfNeeded() {
            guard let alertType else { return }
            showAlert(alertType, exception: exception)
        }

        if _filter.wrappedValue == .reportableExceptionsOnly,
           !exception.isReportable {
            return false
        }

        let sender = String(exception.metadata.sender)
        let fileName = exception.metadata.fileName
        let functionName = exception.metadata.function.components(separatedBy: "(")[0]
        let lineNumber = exception.metadata.line

        if let filterFileNames = _filter.wrappedValue?.fileNames {
            guard filterFileNames.contains(fileName) else { return false }
        }

        defer { // NIT: Should showAlertIfNeeded() be moved up past the filter logic?
            currentTimeLastCalled.wrappedValue = Date.now
            showAlertIfNeeded()

            if exception.isReportable,
               Logger._reportsErrorsAutomatically.wrappedValue {
                Task { @MainActor in
                    @Dependency(\.alertKitConfig.reportDelegate) var reportDelegate: (any AlertKit.ReportDelegate)?
                    reportDelegate?.fileReport(exception.hydrated)
                }
            }
        }

        guard !streamOpen.wrappedValue else {
            logToStream(
                exception.descriptor,
                domain: domain,
                line: lineNumber
            )
            return true
        }

        let headerAffix = exception.isReportable ? "🛑" : ""
        let headerDelimiter = headerAffix.isEmpty ? "" : " "
        let headerInfix = "\(fileName) | \(domain.rawValue.camelCaseToHumanReadable.uppercased()) | \(dateFormatter.string(from: Date.now))"
        let header = "----- \(headerAffix)\(headerDelimiter)\(headerInfix)\(headerDelimiter)\(headerAffix) -----"
        let footer = String(repeating: "-", count: header.count)

        var exceptionString = "\(exception.descriptor) (\(exception.code))"
        if let userInfo = exception.userInfo {
            exceptionString = "\(exception.descriptor) (\(exception.code))\n\(format(userInfo: userInfo))"
        }

        let text =
            """
            \n\(header)
            \(sender).\(functionName)() [\(lineNumber)]\(elapsedTime)
            \(exceptionString)
            \(footer)\n
            """

        log(
            text,
            domain: domain
        )

        return true
    }

    @usableFromInline
    @discardableResult
    static func _logText(
        _ text: String,
        domain: LoggerDomain,
        with alertType: AlertType?,
        metadata: ExceptionMetadata
    ) -> Bool {
        @Dependency(\.loggerDateFormatter) var dateFormatter: DateFormatter

        func showAlertIfNeeded() {
            guard let alertType else { return }
            showAlert(alertType, text: text)
        }

        if _filter.wrappedValue == .exceptionsOnly ||
            _filter.wrappedValue == .reportableExceptionsOnly {
            return false
        }

        let sender = String(metadata.sender)
        let fileName = metadata.fileName
        let functionName = metadata.function.components(separatedBy: "(")[0]
        let lineNumber = metadata.line

        if let filterFileNames = _filter.wrappedValue?.fileNames {
            guard filterFileNames.contains(fileName) else { return false }
        }

        defer { // NIT: Should showAlertIfNeeded() be moved up past the filter logic?
            currentTimeLastCalled.wrappedValue = Date.now
            showAlertIfNeeded()
        }

        guard !streamOpen.wrappedValue else {
            logToStream(
                text,
                domain: domain,
                line: lineNumber
            )
            return true
        }

        let header = "----- \(fileName) | \(domain.rawValue.camelCaseToHumanReadable.uppercased()) | \(dateFormatter.string(from: Date.now)) -----"
        let footer = String(repeating: "-", count: header.count)

        log(
            "\n\(header)\n\(sender).\(functionName)() [\(lineNumber)]\(elapsedTime)\n\(text)\n\(footer)\n",
            domain: domain
        )

        return true
    }

    // MARK: - Streaming

    /// Opens a log stream for grouping related entries under a
    /// single header.
    ///
    /// While a stream is open, subsequent calls to
    /// ``logToStream(_:domain:line:)`` append entries to the current
    /// group without repeating the header. Call
    /// ``closeStream(message:domain:onLine:)`` to finalize the
    /// group.
    ///
    /// If a stream is already open and a `message` is provided, the
    /// message is appended to the existing stream rather than
    /// opening a new one.
    ///
    /// - Parameters:
    ///   - message: An optional message to include in the stream
    ///     header.
    ///   - domain: The domain to log to. The default is ``LoggerDomain/general``.
    ///   - sender: The object or type that opened the stream.
    ///   - fileName: The source file. The default is the caller's
    ///     file.
    ///   - function: The calling function. The default is the
    ///     caller's function.
    ///   - line: The source line number. The default is the caller's
    ///     line.
    public static func openStream(
        message: String? = nil,
        domain: LoggerDomain = .general,
        sender: Any,
        fileName: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        @Dependency(\.loggerDateFormatter) var dateFormatter: DateFormatter

        let metadata = ExceptionMetadata(
            sender: sender,
            fileName: fileName,
            function: function,
            line: line
        )

        if _filter.wrappedValue == .exceptionsOnly ||
            _filter.wrappedValue == .reportableExceptionsOnly {
            return
        }

        let sender = String(metadata.sender)
        let fileName = metadata.fileName
        let functionName = metadata.function.components(separatedBy: "(")[0]
        let lineNumber = metadata.line

        if let filterFileNames = _filter.wrappedValue?.fileNames {
            guard filterFileNames.contains(fileName) else { return }
        }

        ioLock.lock()
        defer { ioLock.unlock() }
        if streamOpen.wrappedValue,
           let message {
            return logToStream(
                message,
                domain: domain,
                line: line
            )
        } else if canLog(to: domain) {
            streamOpen.wrappedValue = true
            currentTimeLastCalled.wrappedValue = Date.now
        }

        guard let message else {
            return log( // swiftlint:disable:next line_length
                "\n*---------- STREAM OPENED @ \(dateFormatter.string(from: Date.now)) ----------*\n[\(fileName) | \(domain.rawValue.camelCaseToHumanReadable.uppercased())]\n\(sender).\(functionName)()\(elapsedTime)",
                domain: domain
            )
        }

        log( // swiftlint:disable:next line_length
            "\n*---------- STREAM OPENED @ \(dateFormatter.string(from: Date.now)) ----------*\n[\(fileName) | \(domain.rawValue.camelCaseToHumanReadable.uppercased())]\n\(sender).\(functionName)()\n[\(lineNumber)]: \(message)\(elapsedTime)",
            domain: domain
        )
    }

    /// Appends a message to the currently open log stream.
    ///
    /// Each entry is prefixed with the source line number and
    /// elapsed time since the last log call. If no stream is
    /// currently open, the message is logged as a standalone entry
    /// instead.
    ///
    /// - Parameters:
    ///   - message: The message to append.
    ///   - domain: The domain to log to. The default is ``LoggerDomain/general``.
    ///   - line: The source line number of the log call.
    public static func logToStream(
        _ message: String,
        domain: LoggerDomain = .general,
        line: Int
    ) {
        if _filter.wrappedValue == .exceptionsOnly ||
            _filter.wrappedValue == .reportableExceptionsOnly {
            return
        }

        guard streamOpen.wrappedValue else {
            log(message, sender: self)
            return
        }

        log(
            "[\(line)]: \(message)\(elapsedTime)",
            domain: domain,
            addPrecedingNewline: true
        )
    }

    /// Closes the currently open log stream.
    ///
    /// An optional final message can be included in the closing
    /// footer. After the stream is closed, subsequent log calls
    /// produce standalone entries as usual.
    ///
    /// If no stream is currently open, this method has no effect
    /// unless a `message` is provided, in which case the message is
    /// logged as a standalone entry.
    ///
    /// - Parameters:
    ///   - message: An optional message to include in the closing
    ///     footer.
    ///   - domain: The domain to log to. The default is ``LoggerDomain/general``.
    ///   - onLine: The source line number to include alongside the
    ///     closing message.
    public static func closeStream(
        message: String? = nil,
        domain: LoggerDomain = .general,
        onLine: Int? = nil
    ) {
        @Dependency(\.loggerDateFormatter) var dateFormatter: DateFormatter

        if _filter.wrappedValue == .exceptionsOnly ||
            _filter.wrappedValue == .reportableExceptionsOnly {
            return
        }

        defer {
            streamOpen.wrappedValue = false
            currentTimeLastCalled.wrappedValue = Date.now
        }

        guard streamOpen.wrappedValue else {
            guard let message else { return }
            return log(message, sender: self)
        }

        guard let message,
              let onLine else {
            return log(
                "*---------- STREAM CLOSED @ \(dateFormatter.string(from: Date.now)) ----------*\n",
                domain: domain,
                addPrecedingNewline: true
            )
        }

        log(
            "[\(onLine)]: \(message)\(elapsedTime)\n*---------- STREAM CLOSED @ \(dateFormatter.string(from: Date.now)) ----------*\n",
            domain: domain,
            addPrecedingNewline: true
        )
    }

    // MARK: - Auxiliary

    @_transparent
    @usableFromInline
    static func _runtimeWarn(
        _ message: String,
        sender: Any,
    ) {
        guard let dso = swiftUIDynamicSharedObject.wrappedValue else { return }
        os_log(
            .fault,
            dso: dso,
            log: OSLog(
                subsystem: "com.apple.runtime-issues",
                category: String(sender)
            ),
            "%@",
            message
        )
    }

    private static func canLog(to domain: LoggerDomain) -> Bool {
        @Dependency(\.build) var build: Build
        guard build.loggingEnabled,
              _subscribedDomains.wrappedValue.contains(domain) else { return false }
        return true
    }

    private static func fallbackLog(
        _ text: String,
        domain: LoggerDomain = .general,
        with alertType: AlertType? = .none
    ) {
        @Dependency(\.loggerDateFormatter) var dateFormatter: DateFormatter

        func showAlertIfNeeded() {
            guard let alertType else { return }
            showAlert(alertType, text: text)
        }

        let header = "----- \(domain.rawValue.camelCaseToHumanReadable.uppercased()) | \(dateFormatter.string(from: Date.now)) -----"
        let footer = String(repeating: "-", count: header.count)

        log(
            "\n\(header)\n[IMPROPERLY FORMATTED METADATA]\n\(text)\n\(footer)\n",
            domain: domain
        )

        currentTimeLastCalled.wrappedValue = Date.now
        showAlertIfNeeded()
    }

    private static func format(userInfo parameters: [String: Any]) -> String {
        guard !parameters.isEmpty else { return "" }
        if parameters.count == 1,
           let (key, value) = parameters.first {
            return "[\(key): \(value)]"
        }

        let keys = parameters.keys.sorted()
        var lines: [String] = []

        for (index, key) in keys.enumerated() {
            let value = parameters[key]!
            if index == 0 {
                lines.append("[\(key): \(value),")
            } else if index == keys.count - 1 {
                lines.append("\(key): \(value)]")
            } else {
                lines.append("\(key): \(value),")
            }
        }

        return lines.joined(separator: "\n")
    }

    private static func log(
        _ text: String,
        domain: LoggerDomain,
        addPrecedingNewline: Bool = false
    ) {
        ioLock.lock()
        defer { ioLock.unlock() }

        if canLog(to: domain) {
            print(text)
        }

        guard !_domainsExcludedFromSessionRecord.wrappedValue.contains(domain) else { return }

        let text = addPrecedingNewline ? "\n\(text)" : text
        guard let data = text.data(using: .utf8) else { return }

        do {
            let fileHandle = try FileHandle(forWritingTo: sessionRecordFilePath)
            defer { try? fileHandle.close() }

            try fileHandle.seekToEnd()
            try fileHandle.write(contentsOf: data)
        } catch let error as NSError
            where error.code == NSFileNoSuchFileError &&
            error.domain == NSCocoaErrorDomain {
            var initialData = utf8BOM
            initialData.append(data)
            try? initialData.write(to: sessionRecordFilePath, options: .atomic)
        } catch {
            return
        }
    }

    private static func showAlert(
        _ type: AlertType,
        exception: Exception? = nil,
        text: String? = nil
    ) {
        Task { @MainActor in
            @Dependency(\.build) var build: Build
            @Dependency(\.coreKit) var core: CoreKit

            guard let userFacingDescriptor = exception?.userFacingDescriptor ?? text else { return }
            core.hud.hide()

            let mockGenericException: Exception = .init(metadata: .init(sender: self))
            let mockTimedOutException: Exception = .timedOut(metadata: .init(sender: self))
            let notGenericDescriptor = userFacingDescriptor != mockGenericException.userFacingDescriptor
            let notTimedOutDescriptor = userFacingDescriptor != mockTimedOutException.userFacingDescriptor
            let hasUserFacingDescriptor = exception?.descriptor != exception?.userFacingDescriptor

            let shouldTranslate = hasUserFacingDescriptor && notGenericDescriptor && notTimedOutDescriptor

            switch type {
            case .errorAlert:
                guard let exception else {
                    return showAlert(
                        .normalAlert,
                        text: text
                    )
                }

                let errorAlert = AKErrorAlert(
                    exception.hydrated,
                    dismissButtonTitle: Localized(SubsystemStringKey.dismiss).wrappedValue
                )

                var translationOptionKeys: [AKErrorAlert.TranslationOptionKey] = shouldTranslate ? [.errorDescription] : []
                if exception.isReportable,
                   !Logger._reportsErrorsAutomatically.wrappedValue {
                    translationOptionKeys.append(.sendErrorReportButtonTitle)
                }

                return await errorAlert.present(translating: translationOptionKeys)

            case .normalAlert:
                let alert = AKAlert(message: userFacingDescriptor)

                if shouldTranslate {
                    return await alert.present(translating: [.message])
                }

                return await alert.present(translating: [])

            case let .toast(
                style: style,
                isPersistent: isPersistent
            ):
                let style = style ?? (exception == nil ? .info : .error)

                var title: String?
                var message: String?

                if let exception,
                   exception.isReportable {
                    title = userFacingDescriptor
                    message = Logger._reportsErrorsAutomatically.wrappedValue
                        ? Localized(SubsystemStringKey.errorReported).wrappedValue
                        : Localized(SubsystemStringKey.tapToReport).wrappedValue
                }

                var reportAction: (@Sendable () -> Void)? {
                    guard let exception,
                          exception.isReportable,
                          !Logger._reportsErrorsAutomatically.wrappedValue else { return nil }
                    return {
                        Task { @MainActor in
                            @Dependency(\.alertKitConfig.reportDelegate) var reportDelegate: (any AlertKit.ReportDelegate)?
                            reportDelegate?.fileReport(exception.hydrated)
                        }
                    }
                }

                Toast.show(
                    .init(
                        isPersistent ? .banner(style: style) : .capsule(style: style),
                        title: title,
                        message: message ?? userFacingDescriptor,
                        perpetuation: isPersistent ? .persistent : .ephemeral(.seconds(10))
                    ),
                    translating: shouldTranslate ? [.message, .title] : [],
                    onTap: reportAction
                )
            }
        }
    }
}

/* MARK: AlertKit LoggerDelegate */

extension Logger {
    struct AlertKitLogger: AlertKit.LoggerDelegate {
        var reportsErrorsAutomatically: Bool { Logger._reportsErrorsAutomatically.wrappedValue }
        init() {}
        func log(
            _ text: String,
            sender: Any,
            fileName: String = #fileID,
            function: String = #function,
            line: Int = #line
        ) {
            Logger.log(
                text,
                domain: .alertKit,
                sender: sender,
                fileName: fileName,
                function: function,
                line: line
            )
        }
    }
}

/* MARK: TranslationLoggerDelegate */

extension Logger {
    struct TranslationLogger: TranslationLoggerDelegate {
        init() {}
        func log(
            _ text: String,
            sender: Any,
            fileName: String = #fileID,
            function: String = #function,
            line: Int = #line
        ) {
            Logger.log(
                text,
                domain: .translation,
                sender: sender,
                fileName: fileName,
                function: function,
                line: line
            )
        }
    }
}

/* MARK: DateFormatter Dependency */

private enum LoggerDateFormatterDependency: DependencyKey {
    static func resolve(_: DependencyValues) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm:ss.SSSS"
        formatter.locale = .init(identifier: "en_US_POSIX")
        return formatter
    }
}

private extension DependencyValues {
    var loggerDateFormatter: DateFormatter {
        get { self[LoggerDateFormatterDependency.self] }
        set { self[LoggerDateFormatterDependency.self] = newValue }
    }
}

/* MARK: Auxiliary */

private extension Exception {
    var hydrated: Exception {
        appending(userInfo: [
            UserInfo.descriptor.rawValue: descriptor,
            UserInfo.errorCode.rawValue: code,
        ])
    }
}

// swiftlint:enable file_length type_body_length
