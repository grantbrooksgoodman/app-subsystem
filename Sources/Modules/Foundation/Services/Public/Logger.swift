//
//  Logger.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

// swiftlint:disable file_length type_body_length

/* Native */
import Foundation

/* Proprietary */
import AlertKit
import Translator

public enum Logger {
    // MARK: - Types

    public enum AlertType {
        /* MARK: Cases */

        case errorAlert
        case normalAlert
        case toast(style: Toast.Style?, isPersistent: Bool = true)

        /* MARK: Properties */

        public static let toast: AlertType = .toast(style: nil)

        /* MARK: Computed Properties */

        public static var toastInPrerelease: AlertType? {
            @Dependency(\.build.milestone) var buildMilestone: Build.Milestone
            guard buildMilestone != .generalRelease else { return nil }
            return .toast
        }

        /* MARK: Methods */

        public static func toastInPrerelease(
            style: Toast.Style?,
            isPersistent: Bool = true
        ) -> AlertType? {
            @Dependency(\.build.milestone) var buildMilestone: Build.Milestone
            guard buildMilestone != .generalRelease else { return nil }
            return .toast(style: style, isPersistent: isPersistent)
        }
    }

    private enum NewlinePlacement {
        case preceding
        case succeeding
        case surrounding
    }

    // MARK: - Properties

    public private(set) static var domainsExcludedFromSessionRecord = [LoggerDomain]()
    public private(set) static var reportsErrorsAutomatically = false
    public private(set) static var subscribedDomains = [LoggerDomain]()

    private static let sessionID = UUID()

    private static var currentTimeLastCalled = Date.now
    private static var streamOpen = false

    // MARK: - Computed Properties

    public static var sessionRecordFilePath: URL {
        @Dependency(\.fileManager) var fileManager: FileManager
        return fileManager.temporaryDirectory.appending(path: "\(sessionID.uuidString).txt")
    }

    private static var elapsedTime: String {
        let time = String(abs(currentTimeLastCalled.seconds(from: Date.now)))
        return time == "0" ? "" : " @ \(time)s FLC"
    }

    // MARK: - Domain Subscription

    public static func subscribe(to domain: LoggerDomain) {
        subscribedDomains.append(domain)
        subscribedDomains = subscribedDomains.unique
    }

    public static func subscribe(to domains: [LoggerDomain]) {
        domains.forEach { subscribe(to: $0) }
    }

    public static func unsubscribe(from domain: LoggerDomain) {
        subscribedDomains = subscribedDomains.filter { $0 != domain }
    }

    public static func unsubscribe(from domains: [LoggerDomain]) {
        domains.forEach { unsubscribe(from: $0) }
    }

    // MARK: - Setters

    public static func setDomainsExcludedFromSessionRecord(_ domainsExcludedFromSessionRecord: [LoggerDomain]) {
        self.domainsExcludedFromSessionRecord = domainsExcludedFromSessionRecord
    }

    public static func setReportsErrorsAutomatically(_ reportsErrorsAutomatically: Bool) {
        self.reportsErrorsAutomatically = reportsErrorsAutomatically
    }

    // MARK: - Logging

    public static func log(
        _ error: Error,
        domain: LoggerDomain = .general,
        with alertType: AlertType? = .none,
        metadata: ExceptionMetadata
    ) {
        log(
            .init(
                error,
                metadata: metadata
            ),
            domain: domain,
            with: alertType
        )
    }

    public static func log(
        _ error: NSError,
        domain: LoggerDomain = .general,
        with alertType: AlertType? = .none,
        metadata: ExceptionMetadata
    ) {
        log(
            .init(
                error,
                metadata: metadata
            ),
            domain: domain,
            with: alertType
        )
    }

    public static func log(
        _ exception: Exception,
        domain: LoggerDomain = .general,
        with alertType: AlertType? = .none
    ) {
        @Dependency(\.alertKitConfig) var alertKitConfig: AlertKit.Config
        @Dependency(\.loggerDateFormatter) var dateFormatter: DateFormatter

        let sender = String(exception.metadata.sender)
        let fileName = exception.metadata.fileName
        let functionName = exception.metadata.function.components(separatedBy: "(")[0]
        let lineNumber = exception.metadata.line

        defer {
            if exception.isReportable,
               Logger.reportsErrorsAutomatically {
                alertKitConfig.reportDelegate?.fileReport(exception.hydrated)
            }
        }

        guard !streamOpen else {
            logToStream(exception.descriptor, domain: domain, line: lineNumber)
            return
        }

        let header = "----- \(fileName) | \(domain.rawValue.camelCaseToHumanReadable.uppercased()) | \(dateFormatter.string(from: Date.now)) -----"
        let footer = String(repeating: "-", count: header.count)
        log(
            "\n\(header)\n\(sender).\(functionName)() [\(lineNumber)]\(elapsedTime)\n\(exception.descriptor) (\(exception.code))",
            domain: domain
        )

        if let userInfo = exception.userInfo {
            printUserInfo(userInfo, domain: domain)
        }

        log(
            "\(footer)\n",
            domain: domain,
            addingNewline: exception.userInfo == nil ? .preceding : nil
        )

        currentTimeLastCalled = Date.now
        showAlertIfNeeded()

        func showAlertIfNeeded() {
            guard let alertType else { return }
            showAlert(alertType, exception: exception)
        }
    }

    public static func log(
        _ text: String,
        domain: LoggerDomain = .general,
        with alertType: AlertType? = .none,
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

        let sender = String(metadata.sender)
        let fileName = metadata.fileName
        let functionName = metadata.function.components(separatedBy: "(")[0]
        let lineNumber = metadata.line

        guard !streamOpen else {
            logToStream(text, domain: domain, line: lineNumber)
            return
        }

        let header = "----- \(fileName) | \(domain.rawValue.camelCaseToHumanReadable.uppercased()) | \(dateFormatter.string(from: Date.now)) -----"
        let footer = String(repeating: "-", count: header.count)
        log(
            "\n\(header)\n\(sender).\(functionName)() [\(lineNumber)]\(elapsedTime)\n\(text)\n\(footer)\n",
            domain: domain
        )

        currentTimeLastCalled = Date.now
        showAlertIfNeeded()

        func showAlertIfNeeded() {
            guard let alertType else { return }
            showAlert(alertType, text: text)
        }
    }

    // MARK: - Streaming

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

        let sender = String(metadata.sender)
        let fileName = metadata.fileName
        let functionName = metadata.function.components(separatedBy: "(")[0]
        let lineNumber = metadata.line

        streamOpen = true
        currentTimeLastCalled = Date.now

        guard let message else {
            log( // swiftlint:disable:next line_length
                "\n*---------- STREAM OPENED @ \(dateFormatter.string(from: Date.now)) ----------*\n[\(fileName) | \(domain.rawValue.camelCaseToHumanReadable.uppercased())]\n\(sender).\(functionName)()\(elapsedTime)",
                domain: domain
            )
            return
        }

        log( // swiftlint:disable:next line_length
            "\n*---------- STREAM OPENED @ \(dateFormatter.string(from: Date.now)) ----------*\n[\(fileName) | \(domain.rawValue.camelCaseToHumanReadable.uppercased())]\n\(sender).\(functionName)()\n[\(lineNumber)]: \(message)\(elapsedTime)",
            domain: domain
        )
    }

    public static func logToStream(
        _ message: String,
        domain: LoggerDomain = .general,
        line: Int
    ) {
        guard streamOpen else {
            log(message, sender: self)
            return
        }

        log("[\(line)]: \(message)\(elapsedTime)", domain: domain)
    }

    public static func closeStream(
        message: String? = nil,
        domain: LoggerDomain = .general,
        onLine: Int? = nil
    ) {
        @Dependency(\.loggerDateFormatter) var dateFormatter: DateFormatter

        guard streamOpen else {
            guard let message else { return }
            log(message, sender: self)
            return
        }

        guard let message,
              let onLine else {
            log(
                "*---------- STREAM CLOSED @ \(dateFormatter.string(from: Date.now)) ----------*\n",
                domain: domain
            )
            return
        }

        log(
            "[\(onLine)]: \(message)\(elapsedTime)\n*---------- STREAM CLOSED @ \(dateFormatter.string(from: Date.now)) ----------*\n",
            domain: domain
        )

        streamOpen = false
        currentTimeLastCalled = Date.now
    }

    // MARK: - Auxiliary

    private static func canLog(to domain: LoggerDomain) -> Bool {
        @Dependency(\.build) var build: Build
        guard build.loggingEnabled,
              subscribedDomains.contains(domain) else { return false }
        return true
    }

    private static func fallbackLog(
        _ text: String,
        domain: LoggerDomain = .general,
        with alertType: AlertType? = .none
    ) {
        @Dependency(\.loggerDateFormatter) var dateFormatter: DateFormatter

        let header = "----- \(domain.rawValue.camelCaseToHumanReadable.uppercased()) | \(dateFormatter.string(from: Date.now)) -----"
        let footer = String(repeating: "-", count: header.count)
        log(
            "\n\(header)\n[IMPROPERLY FORMATTED METADATA]\n\(text)\n\(footer)\n",
            domain: domain
        )

        currentTimeLastCalled = Date.now
        showAlertIfNeeded()

        func showAlertIfNeeded() {
            guard let alertType else { return }
            showAlert(alertType, text: text)
        }
    }

    private static func log(
        _ text: String,
        domain: LoggerDomain,
        addingNewline placement: NewlinePlacement? = nil
    ) {
        if canLog(to: domain) {
            print(text)
        }

        guard !domainsExcludedFromSessionRecord.contains(domain) else { return }

        var text = text
        if let placement {
            switch placement {
            case .preceding:
                text = "\n\(text)"
            case .succeeding:
                text = "\(text)\n"
            case .surrounding:
                text = "\n\(text)\n"
            }
        }

        let data = Data(text.utf8)

        do {
            let fileHandle = try FileHandle(forWritingTo: sessionRecordFilePath)
            try fileHandle.seekToEnd()
            try fileHandle.write(contentsOf: data)
            try fileHandle.close()
        } catch let error as NSError where error.code == NSFileNoSuchFileError && error.domain == NSCocoaErrorDomain {
            try? data.write(to: sessionRecordFilePath, options: .atomic)
        } catch { return }
    }

    private static func printUserInfo(_ parameters: [String: Any], domain: LoggerDomain) {
        guard !parameters.isEmpty else { return }
        guard parameters.count > 1 else {
            log("[\(parameters.first!.key): \(parameters.first!.value)]", domain: domain, addingNewline: .surrounding)
            return
        }

        for (index, key) in parameters.keys.sorted().enumerated() {
            switch index {
            case 0:
                log("[\(key): \(parameters[key]!),", domain: domain, addingNewline: .preceding)
            case parameters.count - 1:
                log("\(key): \(parameters[key]!)]", domain: domain, addingNewline: .surrounding)
            default:
                log("\(key): \(parameters[key]!),", domain: domain, addingNewline: .preceding)
            }
        }
    }

    private static func showAlert(
        _ type: AlertType,
        exception: Exception? = nil,
        text: String? = nil
    ) {
        Task {
            @Dependency(\.alertKitConfig) var alertKitConfig: AlertKit.Config
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
                    showAlert(.normalAlert, text: text)
                    return
                }

                let errorAlert = AKErrorAlert(
                    exception.hydrated,
                    dismissButtonTitle: AppSubsystem.delegates.localizedStrings.dismiss
                )

                var translationOptionKeys: [AKErrorAlert.TranslationOptionKey] = shouldTranslate ? [.errorDescription] : []
                if exception.isReportable,
                   !Logger.reportsErrorsAutomatically {
                    translationOptionKeys.append(.sendErrorReportButtonTitle)
                }

                return await errorAlert.present(translating: translationOptionKeys)

            case .normalAlert:
                let alert = AKAlert(message: userFacingDescriptor)

                if shouldTranslate {
                    return await alert.present(translating: [.message])
                }

                return await alert.present(translating: [])

            case let .toast(style: style, isPersistent: isPersistent):
                let style = style ?? (exception == nil ? .info : .error)

                var title: String?
                var message: String?

                if let exception,
                   exception.isReportable {
                    let strings = AppSubsystem.delegates.localizedStrings
                    title = userFacingDescriptor
                    message = Logger.reportsErrorsAutomatically ? strings.errorReported : strings.tapToReport
                }

                var reportAction: (() -> Void)? {
                    guard let exception,
                          exception.isReportable,
                          !Logger.reportsErrorsAutomatically else { return nil }
                    return { alertKitConfig.reportDelegate?.fileReport(exception.hydrated) }
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
        public init() {}
        public var reportsErrorsAutomatically: Bool { Logger.reportsErrorsAutomatically }
        public func log(
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
        public init() {}
        public func log(
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
    public static func resolve(_: DependencyValues) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm:ss.SSSS"
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
            CommonParameter.descriptor.rawValue: descriptor,
            CommonParameter.errorCode.rawValue: code,
        ])
    }
}

// swiftlint:enable file_length type_body_length
