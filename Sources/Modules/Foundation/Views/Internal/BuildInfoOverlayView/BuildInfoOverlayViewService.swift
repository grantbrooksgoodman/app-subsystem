//
//  BuildInfoOverlayViewService.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

/* Proprietary */
import AlertKit

struct BuildInfoOverlayViewService {
    // MARK: - Dependencies

    @Dependency(\.build) private var build: Build
    @Dependency(\.currentCalendar) private var calendar: Calendar
    @Dependency(\.reportDelegate) private var reportDelegate: ReportDelegate

    // MARK: - Properties

    private var buildInfoButtonMessage: (string: String, messageAttributes: AttributedStringConfig?) { getBuildInfoButtonMessage() }

    // MARK: - Build Info Button Tapped

    func buildInfoButtonTapped() {
        Task { @MainActor in
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            let viewBuildInformationAction: AKAction = .init("View Build Information") {
                self.viewBuildInformationButtonTapped()
            }

            let developerModeButtonTitle = "\(build.isDeveloperModeEnabled ? "Disable" : "Enable") Developer Mode"
            let developerModeAction: AKAction = .init(
                developerModeButtonTitle,
                style: developerModeButtonTitle.hasPrefix("Enable") ? .default : .destructive
            ) {
                DevModeService.promptToToggle()
            }

            let alert = AKAlert(
                title: RuntimeStorage.languageCode == "en" ? "Project \(build.codeName)" : "Project ⌘\(build.codeName)⌘",
                message: buildInfoButtonMessage.string,
                actions: [
                    viewBuildInformationAction,
                    developerModeAction,
                    .cancelAction(title: AppSubsystem.delegates.localizedStrings.dismiss),
                ]
            )

            if let messageAttributes = buildInfoButtonMessage.messageAttributes {
                alert.setMessageAttributes(messageAttributes.alertKitMapping)
            }

            await alert.present(translating: [.message, .title])
        }
    }

    // MARK: - Send Feedback Button Tapped

    func sendFeedbackButtonTapped() {
        Task { @MainActor in
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            await AKActionSheet(
                title: "File a Report",
                actions: [
                    .init(AppSubsystem.delegates.localizedStrings.sendFeedback) {
                        reportDelegate.sendFeedback()
                    },
                    .init("Report Bug") {
                        reportDelegate.reportBug()
                    },
                ],
                cancelButtonTitle: AppSubsystem.delegates.localizedStrings.cancel,
                sourceItem: .custom(.string(AppSubsystem.delegates.localizedStrings.sendFeedback))
            ).present(translating: [.actions(), .title])
        }
    }

    // MARK: - Auxiliary

    private func getBuildInfoButtonMessage() -> (String, AttributedStringConfig?) {
        let milestoneString = build.milestone.rawValue
        let expiryString = build.isTimebombActive ? "\n\n\(build.expiryInfoString)" : ""

        var message = "This is a\(milestoneString == "alpha" ? "n" : "") \(milestoneString) version of ⌘project code name \(build.codeName)⌘.\(expiryString)"
        if build.appStoreReleaseVersion > 0 {
            message = "This is a pre-release update to ⌘\(build.finalName)⌘.\(expiryString)"
        }

        // swiftlint:disable:next line_length
        message += "\n\nAll features presented here are subject to change, and any new or previously undisclosed information presented within this software is to remain strictly confidential.\n\nRedistribution of this software by unauthorized parties in any way, shape, or form is strictly prohibited.\n\nBy continuing your use of this software, you acknowledge your agreement to the above terms.\n\nAll content herein, unless otherwise stated, is copyright ⌘© \(calendar.dateComponents([.year], from: .now).year!) NEOTechnica Corporation⌘. All rights reserved."

        guard let dateStringRanges = message.dateStringRanges else { return (message, nil) }
        return (message, .init(
            [.font: UIFont.systemFont(ofSize: 13)],
            secondaryAttributes: [
                .init([.foregroundColor: UIColor.red], stringRanges: dateStringRanges),
            ]
        ))
    }

    private func viewBuildInformationButtonTapped() {
        let buildMilestoneString = "Build Milestone\n\(build.milestone.rawValue.capitalized)"
        let bundleVersionString = "Bundle Version\n\(build.bundleVersion) (\(String(build.buildNumber)))"
        let projectIDString = "Project ID\n\(build.projectID)"
        let revisionString = "Revision\n\(build.bundleRevision) (\(String(build.revisionBuildNumber)))"
        let skuString = "SKU\n\(build.buildSKU)"

        let message = [
            buildMilestoneString,
            bundleVersionString,
            projectIDString,
            revisionString,
            skuString,
        ].joined(separator: "\n\n")

        let alert = AKAlert(message: message)
        alert.setMessageAttributes(.init(
            [.font: UIFont.systemFont(ofSize: 13)],
            secondaryAttributes: [
                .init(
                    [.font: UIFont.boldSystemFont(ofSize: 14)],
                    stringRanges: [
                        "Build Number",
                        "Build Milestone",
                        "Bundle Version",
                        "Project ID",
                        "Revision",
                        "SKU",
                    ]
                ),
            ]
        ))

        Task { await alert.present(translating: []) }
    }
}

private extension String {
    var dateStringRanges: [String]? {
        @Dependency(\.currentCalendar) var calendar: Calendar
        let dataDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)

        guard let match = dataDetector?
            .matches(
                in: self,
                options: [],
                range: NSRange(location: 0, length: utf16.count)
            ).first,
            let date = match.date,
            let matchRange = Range(match.range, in: self) else { return self == sanitized ? nil : sanitized.dateStringRanges }

        let dateString = String(self[matchRange])
        let dateComponents = calendar.dateComponents([.day, .month, .year], from: date)
        guard !dateString.digits.isBlank else { return self == sanitized ? nil : sanitized.dateStringRanges }

        var stringRanges = [
            dateComponents.day,
            dateComponents.month,
            dateComponents.year,
        ].compactMap { $0.map(String.init) }

        stringRanges.append(contentsOf: stringRanges.map { "0\($0)" })

        let digitComponents = "0123456789".components
        stringRanges.append(contentsOf: digitComponents.map { "/\($0)" })
        stringRanges.append(contentsOf: digitComponents.map { "-\($0)" })
        stringRanges.append(contentsOf: digitComponents.map { ".\($0)" })

        stringRanges.append(dateString)
        return stringRanges
    }
}
