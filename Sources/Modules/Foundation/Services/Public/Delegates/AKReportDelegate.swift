//
//  AKReportDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import MessageUI

/* Proprietary */
import AlertKit

public struct ReportDelegate: AlertKit.ReportDelegate {
    // MARK: - Dependencies

    @Dependency(\.alertKitConfig) private var alertKitConfig: AlertKit.Config
    @Dependency(\.build) private var build: Build
    @Dependency(\.coreKit) private var core: CoreKit
    @Dependency(\.timestampDateFormatter) private var dateFormatter: DateFormatter
    @Dependency(\.fileManager) private var fileManager: FileManager
    @Dependency(\.uiApplication.keyViewController?.leafViewController) private var leafViewController: UIViewController?
    @Dependency(\.jsonEncoder) private var jsonEncoder: JSONEncoder
    @Dependency(\.mailComposer) private var mailComposer: MailComposer

    // MARK: - Computed Properties

    private var bundleVersionString: String {
        "\(build.milestone == .generalRelease ? build.finalName : build.codeName) (\(build.bundleVersion))"
    }

    private var loggerSessionRecordAttachment: MailComposer.AttachmentData? {
        let loggerSessionRecordFilePathString = Logger.sessionRecordFilePath.path()

        guard let loggerSessionRecordData = fileManager.contents(atPath: loggerSessionRecordFilePathString),
              let loggerSessionRecordFileName = loggerSessionRecordFilePathString
              .components(separatedBy: "/")
              .last?
              .components(separatedBy: ".")
              .first else { return nil }

        return .init(
            loggerSessionRecordData,
            fileName: "logger_session_\(loggerSessionRecordFileName).txt",
            mimeType: "text/plain"
        )
    }

    // MARK: - Init

    fileprivate init() {}

    // MARK: - Register with Dependencies

    public static func registerWithDependencies() {
        @Dependency(\.alertKitConfig) var alertKitConfig: AlertKit.Config
        alertKitConfig.registerReportDelegate(ReportDelegate())
    }

    // MARK: - AlertKit.ReportDelegate Conformance

    public func fileReport(_ error: any AlertKit.Errorable) {
        Task {
            await composeMessage(
                subject: "\(bundleVersionString) Error Report",
                body: nil,
                prompt: nil,
                error: error
            )
        }
    }

    // MARK: - Report Bug

    public func reportBug() {
        Task {
            await composeMessage(
                subject: "\(bundleVersionString) Bug Report",
                body: "In the appropriate section, please describe the error encountered and the steps to reproduce it.",
                prompt: "Description/Steps to Reproduce",
                error: nil
            )
        }
    }

    // MARK: - Send Feedback

    public func sendFeedback() {
        Task {
            await composeMessage(
                subject: "\(bundleVersionString) Feedback Report",
                body: "Any general feedback is appreciated in the appropriate section.",
                prompt: "General Feedback",
                error: nil
            )
        }
    }

    // MARK: - Auxiliary

    @MainActor
    private func composeMessage(
        subject: String,
        body: String?,
        prompt: String?,
        error: (any AlertKit.Errorable)?
    ) async {
        func compose(body: String?, prompt: String?) {
            var bodyTuple: (String, Bool)?

            if let body,
               let prompt {
                var bodyHTML = "<i>\(body.split(separator: ".")[0]).</i><p></p><b>\(prompt):</b><p></p>"
                if body.split(separator: ".").count > 1 {
                    bodyHTML = "<i>\(body.split(separator: ".")[0]).<p></p>\(body.split(separator: ".")[1]).</i><p></p>"
                }
                bodyTuple = (bodyHTML, true)
            }

            var attachments: [MailComposer.AttachmentData] = []
            if let loggerSessionRecordAttachment {
                attachments.append(loggerSessionRecordAttachment)
            }

            if let reportMetadataAttachment = reportMetadataAttachment(error) {
                attachments.append(reportMetadataAttachment)
            }

            mailComposer.compose(
                subject: subject,
                body: bodyTuple,
                recipients: ["me@grantbrooks.io"],
                attachments: attachments
            )

            mailComposer.onComposeFinished { onComposeFinished($0) }
        }

        guard mailComposer.canSendMail else {
            let exception: Exception = .init(
                "Device is not configured for e-mail.",
                isReportable: false,
                userInfo: [Exception.UserInfo.userFacingDescriptor.rawValue: AppSubsystem.delegates.localizedStrings.noEmail],
                metadata: .init(sender: self)
            )

            Logger.log(exception)
            await AKErrorAlert(
                exception,
                dismissButtonTitle: AppSubsystem.delegates.localizedStrings.dismiss
            ).present(translating: [])
            return
        }

        guard let body,
              let prompt else { return compose(body: nil, prompt: nil) }

        guard let translationDelegate = alertKitConfig.translationDelegate else { return }
        let getTranslationsResult = await translationDelegate.getTranslations(
            [
                .init(body),
                .init(prompt),
            ],
            languagePair: .system,
            hud: alertKitConfig.translationHUDConfig,
            timeout: alertKitConfig.translationTimeoutConfig
        )

        switch getTranslationsResult {
        case let .success(translations):
            compose(
                body: translations.first(where: { $0.input.value == body })?.output ?? body,
                prompt: translations.first(where: { $0.input.value == prompt })?.output ?? prompt
            )

        case let .failure(error):
            Logger.log(.init(error, metadata: .init(sender: self)))
            compose(body: body, prompt: prompt)
        }
    }

    private func onComposeFinished(_ result: Result<MFMailComposeResult, Error>) {
        switch result {
        case let .failure(error):
            Logger.log(
                .init(error, metadata: .init(sender: self)),
                with: .toast
            )

        case let .success(result):
            switch result {
            case .failed:
                Logger.log(
                    .init(metadata: .init(sender: self)),
                    with: .toast
                )

            case .sent:
                Toast.show(.init(
                    .capsule(style: .success),
                    message: AppSubsystem.delegates.localizedStrings.reportSent,
                    perpetuation: .ephemeral(.seconds(3))
                ))

            default: ()
            }
        }
    }

    private func reportMetadataAttachment(_ error: (any AlertKit.Errorable)? = nil) -> MailComposer.AttachmentData? {
        func attachmentData(_ dictionary: [String: String]) -> MailComposer.AttachmentData? {
            do {
                return try .init(
                    jsonEncoder.encode(dictionary),
                    fileName: "metadata.log",
                    mimeType: "application/json"
                )
            } catch {
                Logger.log(.init(error, metadata: .init(sender: self)))
                return nil
            }
        }

        var sections = [
            "build_sku": build.buildSKU,
            "bundle_revision": "\(build.bundleRevision) (\(build.revisionBuildNumber))",
            "bundle_version": "\(build.bundleVersion) (\(build.buildNumber)\(build.milestone.shortString))",
            "connection_status": build.isOnline ? "online" : "offline",
            "device_model": "\(SystemInformation.modelName) (\(SystemInformation.modelCode.lowercased()))",
            "language_code": RuntimeStorage.languageCode,
            "os_version": SystemInformation.osVersion.lowercased(),
            "project_id": build.projectID,
            "timestamp": dateFormatter.string(from: .now),
        ]

        if let leafViewController {
            sections["view_id"] = leafViewController.descriptor
        }

        guard let error else { return attachmentData(sections) }

        var errorDescription = error.description
        if let descriptor = error.userInfo?[Exception.UserInfo.descriptor.rawValue] as? String,
           let code = error.userInfo?[Exception.UserInfo.errorCode.rawValue] as? String {
            errorDescription = "\(descriptor) (\(code.uppercased()))"
        }

        sections["error_description"] = errorDescription
        sections["error_id"] = error.id

        if let additionalParameters = error.userInfo?
            .filter({ $0.key != "Descriptor" })
            .filter({ $0.key != "ErrorCode" }),
            !additionalParameters.isEmpty {
            sections["error_parameters"] = additionalParameters
                .withCapitalizedKeys
                .description
                .replacingOccurrences(of: "\"", with: "'")
        }

        return attachmentData(sections)
    }
}

/* MARK: Dependency */

public enum ReportDelegateDependency: DependencyKey {
    public static func resolve(_ dependencies: DependencyValues) -> ReportDelegate {
        (dependencies.alertKitConfig.reportDelegate as? ReportDelegate) ?? .init()
    }
}

public extension DependencyValues {
    var reportDelegate: ReportDelegate {
        get { self[ReportDelegateDependency.self] }
        set { self[ReportDelegateDependency.self] = newValue }
    }
}
