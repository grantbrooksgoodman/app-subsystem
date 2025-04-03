//
//  Build.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public final class Build {
    // MARK: - Types

    public enum Milestone: String {
        /* MARK: Cases */

        case preAlpha = "pre-alpha" /* Typically builds 0-1500. */
        case alpha /* Typically builds 1500-3000. */
        case beta /* Typically builds 3000-6000. */
        case releaseCandidate = "release candidate" /* Typically builds 6000 onwards. */
        case generalRelease = "general"

        /* MARK: Properties */

        public var shortString: String {
            switch self {
            case .preAlpha:
                return "p"
            case .alpha:
                return "a"
            case .beta:
                return "b"
            case .releaseCandidate:
                return "c"
            case .generalRelease:
                return "g"
            }
        }
    }

    // MARK: - Dependencies

    @Dependency(\.buildSKUDateFormatter) private var buildSKUDateFormatter: DateFormatter
    @Dependency(\.currentCalendar) private var calendar: Calendar
    @Dependency(\.expiryInfoStringDateFormatter) private var expiryInfoStringDateFormatter: DateFormatter
    @Dependency(\.mainBundle) private var mainBundle: Bundle
    @Dependency(\.projectIDDateFormatter) private var projectIDDateFormatter: DateFormatter

    // MARK: - Properties

    // String
    public let codeName: String
    public let dmyFirstCompileDateString: String
    public let finalName: String

    // Other
    public let appStoreBuildNumber: Int
    public let loggingEnabled: Bool
    public let milestone: Milestone

    // MARK: - Computed Properties

    // Bool
    public var isDeveloperModeEnabled: Bool { getIsDeveloperModeEnabled() }
    public var isOnline: Bool { getNetworkStatus() }
    public var isTimebombActive: Bool { getIsTimebombActive() }

    // Int
    public var appStoreReleaseVersion: Int { getAppStoreReleaseVersion() }
    public var buildNumber: Int { getBuildNumber() }
    public var revisionBuildNumber: Int { getRevisionBuildNumber() }

    // String
    public var buildSKU: String { getBuildSKU() }
    public var bundleVersion: String { getBundleVersion() }
    public var bundleRevision: String { getBundleRevision() }
    public var expirationOverrideCode: String { getExpirationOverrideCode() }
    public var expiryInfoString: String { getExpiryInfoString() }
    public var projectID: String { getProjectID() }

    // Other
    public var expiryDate: Date { getExpiryDate() }

    private var buildDateUnixDouble: TimeInterval { getBuildDateUnixDouble() }
    private var infoDictionary: [String: Any] { mainBundle.infoDictionary ?? [:] }

    // MARK: - Init

    public init(
        appStoreBuildNumber: Int,
        codeName: String,
        dmyFirstCompileDateString: String,
        finalName: String,
        loggingEnabled: Bool,
        milestone: Milestone
    ) {
        self.appStoreBuildNumber = appStoreBuildNumber
        self.codeName = codeName
        self.dmyFirstCompileDateString = dmyFirstCompileDateString
        self.finalName = finalName
        self.loggingEnabled = loggingEnabled
        self.milestone = milestone
    }

    // MARK: - Setters

    public func setIsDeveloperModeEnabled(_ isDeveloperModeEnabled: Bool) {
        @Persistent(.hidesBuildInfoOverlay) var hidesBuildInfoOverlay: Bool?
        if !isDeveloperModeEnabled,
           let hidesBuildInfoOverlay,
           hidesBuildInfoOverlay {
            BuildInfoOverlay.show()
        }

        @Persistent(.isDeveloperModeEnabled) var persistedValue: Bool?
        persistedValue = isDeveloperModeEnabled
        setIsTimebombActive(isDeveloperModeEnabled ? isTimebombActive : milestone == .generalRelease ? false : true)
    }

    public func setIsTimebombActive(_ isTimebombActive: Bool) {
        @Persistent(.isTimebombActive) var persistedValue: Bool?
        persistedValue = isTimebombActive
    }

    // MARK: - Computed Property Getters

    private func getAppStoreReleaseVersion() -> Int {
        Int(bundleVersion.components(separatedBy: ".").first ?? "") ?? 0
    }

    private func getBuildDateUnixDouble() -> TimeInterval {
        guard let cfBuildDate = infoDictionary["CFBuildDate"] as? String,
              cfBuildDate != "1183100400" else {
            return floor(Date.now.timeIntervalSince1970)
        }

        return .init(cfBuildDate) ?? 0
    }

    private func getBuildNumber() -> Int {
        Int(infoDictionary["CFBundleVersion"] as? String ?? "") ?? 0
    }

    private func getBuildSKU() -> String {
        let formattedBuildDateString = buildSKUDateFormatter.string(from: Date(timeIntervalSince1970: buildDateUnixDouble))

        var threeLetterID = codeName.uppercased()
        if codeName.count > 3 {
            let prefix = String(codeName.first!)
            let suffix = String(codeName.last!)
            let middleLetterIndex = codeName.index(codeName.startIndex, offsetBy: Int((Double(codeName.count) / 2).rounded(.down)))
            threeLetterID = "\(prefix)\(String(codeName[middleLetterIndex]))\(suffix)".uppercased()
        }

        return "\(formattedBuildDateString)-\(threeLetterID)-\(String(format: "%06d", getBuildNumber()))\(milestone.shortString)"
    }

    private func getBundleVersion() -> String {
        infoDictionary["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    private func getBundleRevision() -> String {
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        let revisionMilestone = getRevisionBuildNumber() / 150

        func letterRepresentation(_ index: Int) -> String {
            guard let letter = alphabet.itemAt(index) else { return "A" }
            return .init(letter)
        }

        if revisionMilestone >= alphabet.count {
            var remainder = revisionMilestone
            while remainder > alphabet.count {
                remainder /= alphabet.count
            }
            return letterRepresentation(remainder)
        } else {
            return letterRepresentation(revisionMilestone)
        }
    }

    private func getExpirationOverrideCode() -> String {
        guard !codeName.isEmpty,
              let firstCharacter = codeName.first,
              let lastCharacter = codeName.last else { return "000000" }

        let firstLetter = String(firstCharacter)
        let lastLetter = String(lastCharacter)

        let middleIndex = codeName.index(
            codeName.startIndex,
            offsetBy: Int((Double(codeName.count) / 2).rounded(.down))
        )
        let middleLetter = String(codeName[middleIndex])

        return [firstLetter, middleLetter, lastLetter].reduce(into: [String]()) { partialResult, letter in
            if let position = letter.alphabeticalPosition {
                partialResult.append(.init(format: "%02d", position))
            }
        }.joined()
    }

    private func getExpiryDate() -> Date {
        calendar.date(
            byAdding: .day,
            value: 30,
            to: .init(
                timeIntervalSince1970: buildDateUnixDouble
            ).comparator
        )?.comparator ?? .distantPast
    }

    private func getExpiryInfoString() -> String {
        let expiryDate = getExpiryDate()
        let expiryDateComponents = calendar.dateComponents(
            [.day],
            from: Date.now.comparator,
            to: expiryDate.comparator
        )

        guard let daysUntilExpiry = expiryDateComponents.day else { return .init() }

        var expiryInfoString = "The evaluation period for this build will expire on ⌘\(expiryInfoStringDateFormatter.string(from: expiryDate))⌘."
        expiryInfoString += " After this date, the entry of a six-digit expiration override code will be required to continue using this software."
        expiryInfoString += " It is strongly encouraged that the build be updated before the end of the evaluation period."

        guard daysUntilExpiry <= 0 else { return expiryInfoString }
        return "The evaluation period for this build ended on ⌘\(expiryInfoStringDateFormatter.string(from: expiryDate))⌘."
    }

    private func getIsDeveloperModeEnabled() -> Bool {
        @Persistent(.isDeveloperModeEnabled) var persistedValue: Bool?
        return milestone == .generalRelease ? false : persistedValue ?? false
    }

    private func getIsTimebombActive() -> Bool {
        @Persistent(.isTimebombActive) var persistedValue: Bool?
        return milestone == .generalRelease ? false : persistedValue ?? true
    }

    private func getNetworkStatus() -> Bool {
        guard let reachability = try? Reachability() else { return false }
        return reachability.connection.description != "No Connection"
    }

    private func getProjectID() -> String {
        let firstCompileDate = projectIDDateFormatter.date(from: dmyFirstCompileDateString) ?? projectIDDateFormatter.date(from: "29062007")!

        let codeName = codeName.lowercasedTrimmingWhitespaceAndNewlines.isEmpty ? "Template" : codeName.lowercasedTrimmingWhitespaceAndNewlines
        let firstLetterPosition = String(codeName.first!).alphabeticalPosition ?? 13
        let lastLetterPosition = String(codeName.last!).alphabeticalPosition ?? 13

        let dateComponents = calendar.dateComponents(
            [.day, .month, .year],
            from: firstCompileDate
        )

        let offset = Int((Double(codeName.count) / 2).rounded(.down))
        let middleLetterIndex = codeName.index(codeName.startIndex, offsetBy: offset)
        let middleLetter = String(codeName[middleLetterIndex])
        let middleLetterPosition = middleLetter.alphabeticalPosition ?? 13

        let multipliedLetterPositions = firstLetterPosition * middleLetterPosition * lastLetterPosition
        let multipliedDateComponents = dateComponents.day! * dateComponents.month! * dateComponents.year!
        let multipliedConstants = String(multipliedLetterPositions * multipliedDateComponents).map { String($0) }

        var projectIDComponents = [String]()

        for integerString in multipliedConstants {
            projectIDComponents.append(integerString)

            guard let integer = Int(integerString) else { continue }
            let cipheredMiddleLetter = middleLetter.ciphered(by: integer).uppercased()
            projectIDComponents.append(cipheredMiddleLetter)
        }

        projectIDComponents = Array(NSOrderedSet(array: projectIDComponents)) as? [String] ?? []

        if projectIDComponents.count > 8 {
            while projectIDComponents.count > 8 {
                projectIDComponents.removeLast()
            }
        } else if projectIDComponents.count < 8 {
            var currentLetter = middleLetter

            while projectIDComponents.count < 8 {
                guard let position = currentLetter.alphabeticalPosition else { continue }
                currentLetter = currentLetter.ciphered(by: position)

                guard !projectIDComponents.contains(currentLetter) else { continue }
                projectIDComponents.append(currentLetter)
            }
        }

        return (Array(NSOrderedSet(array: projectIDComponents)) as? [String] ?? []).joined()
    }

    private func getRevisionBuildNumber() -> Int {
        buildNumber - appStoreBuildNumber < 0 ? 0 : buildNumber - appStoreBuildNumber
    }
}

/* MARK: Date Formatter Dependencies */

private enum BuildSKUDateFormatterDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "ddMMyy"
        return formatter
    }
}

private enum ExpiryInfoStringDateFormatterDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}

private enum ProjectIDDateFormatterDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "ddMMyyyy"
        return formatter
    }
}

private extension DependencyValues {
    var buildSKUDateFormatter: DateFormatter {
        get { self[BuildSKUDateFormatterDependency.self] }
        set { self[BuildSKUDateFormatterDependency.self] = newValue }
    }

    var expiryInfoStringDateFormatter: DateFormatter {
        get { self[ExpiryInfoStringDateFormatterDependency.self] }
        set { self[ExpiryInfoStringDateFormatterDependency.self] = newValue }
    }

    var projectIDDateFormatter: DateFormatter {
        get { self[ProjectIDDateFormatterDependency.self] }
        set { self[ProjectIDDateFormatterDependency.self] = newValue }
    }
}
