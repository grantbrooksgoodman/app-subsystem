//
//  Build.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Combine
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

    // MARK: - Properties

    public let appStoreBuildNumber: Int
    public let codeName: String
    public let finalName: String
    public let loggingEnabled: Bool
    public let milestone: Milestone

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    public var appStoreReleaseVersion: Int { getAppStoreReleaseVersion() }
    public var buildNumber: Int { getBuildNumber() }
    public var buildSKU: String { getBuildSKU() }
    public var bundleVersion: String { getBundleVersion() }
    public var bundleRevision: String { getBundleRevision() }
    public var expirationOverrideCode: String { getExpirationOverrideCode() }
    public var expiryDate: Date { getExpiryDate() }
    public var expiryInfoString: String { getExpiryInfoString() }
    public var isDeveloperModeEnabled: Bool { getIsDeveloperModeEnabled() }
    public var isOnline: Bool { getNetworkStatus() }
    public var isTimebombActive: Bool { getIsTimebombActive() }
    public var projectID: String { getProjectID() }
    public var revisionBuildNumber: Int { getRevisionBuildNumber() }

    private var buildDateUnixDouble: TimeInterval { getBuildDateUnixDouble() }
    private var firstCompileDate: Date { getFirstCompileDate() }
    private var infoDictionary: [String: Any] { mainBundle.infoDictionary ?? [:] }

    // MARK: - Init

    public init(
        appStoreBuildNumber: Int,
        codeName: String,
        finalName: String,
        loggingEnabled: Bool,
        milestone: Milestone
    ) {
        self.appStoreBuildNumber = appStoreBuildNumber
        self.codeName = codeName
        self.finalName = finalName
        self.loggingEnabled = loggingEnabled
        self.milestone = milestone

        Task.background { @MainActor in
            listenForForcedUpdateStatusChanges()
        }
    }

    // MARK: - Setters

    func setIsDeveloperModeEnabled(_ isDeveloperModeEnabled: Bool) {
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

    func setIsTimebombActive(_ isTimebombActive: Bool) {
        @Persistent(.isTimebombActive) var persistedValue: Bool?
        persistedValue = isTimebombActive
    }

    // MARK: - Computed Property Getters

    private func getAppStoreReleaseVersion() -> Int {
        Int(bundleVersion.components(separatedBy: ".").first ?? "") ?? 0
    }

    private func getBuildDateUnixDouble() -> TimeInterval {
        guard let cfBuildDate = infoDictionary["CFBuildDate"] as? String,
              cfBuildDate != "1183100400" else { return floor(Date.now.timeIntervalSince1970) }
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
            var revisionLetters = "Z"

            while remainder >= alphabet.count {
                remainder -= alphabet.count
                guard remainder < alphabet.count else {
                    revisionLetters += "Z"
                    continue
                }

                revisionLetters += letterRepresentation(remainder)
            }

            let zCount = revisionLetters.components.count(of: "Z")
            return zCount > 3 ? "Z\(zCount)\(revisionLetters.filter { $0 != "Z" })" : revisionLetters
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

    private func getFirstCompileDate() -> Date {
        var timeInterval: TimeInterval = floor(Date.now.timeIntervalSince1970)
        if let firstCompileDateString = infoDictionary["CFFirstCompileDate"] as? String {
            timeInterval = .init(firstCompileDateString) ?? timeInterval
        }

        return .init(timeIntervalSince1970: timeInterval).comparator
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
        // Normalize code name

        let codeName = codeName.lowercasedTrimmingWhitespaceAndNewlines
        let rawName = codeName.isEmpty ? "template" : codeName

        // Get code name letter positions

        let firstLetterPosition = rawName.components.first?.alphabeticalPosition ?? 13
        let lastLetterPosition = rawName.components.last?.alphabeticalPosition ?? 13
        let middleLetter = String(rawName.components.itemAt(
            rawName.distance(
                to: rawName.index(
                    rawName.startIndex,
                    offsetBy: rawName.count / 2
                )
            )
        ) ?? "A")
        let middleLetterPosition = middleLetter.alphabeticalPosition ?? 13

        // Calculate numeric ID

        let dateComponents = calendar.dateComponents(
            [.day, .month, .year],
            from: firstCompileDate
        )

        let dateProduct = (dateComponents.day! * dateComponents.month! * dateComponents.year!)
        let letterProduct = firstLetterPosition * middleLetterPosition * lastLetterPosition
        let numericID = String(letterProduct * dateProduct).digits

        // Build alphanumeric ID

        var alphanumericIDComponents = [String]()
        numericID.compactMap { Int(String($0)) }.forEach { digit in
            alphanumericIDComponents.append(String(digit))
            alphanumericIDComponents.append(middleLetter.ciphered(by: digit).uppercased())
        }

        alphanumericIDComponents = Array(alphanumericIDComponents.unique.prefix(8))

        // If ID is too short, continuously add ciphered middle letter until 8 characters

        var currentLetter = middleLetter
        while alphanumericIDComponents.count < 8 {
            guard let position = currentLetter.alphabeticalPosition else { break }
            currentLetter = currentLetter.ciphered(by: position)

            guard !alphanumericIDComponents.contains(currentLetter) else { continue }
            alphanumericIDComponents.append(currentLetter)
        }

        return alphanumericIDComponents.joined()
    }

    private func getRevisionBuildNumber() -> Int {
        buildNumber - appStoreBuildNumber < 0 ? 0 : buildNumber - appStoreBuildNumber
    }

    // MARK: - Forced Update Modal Listener

    @MainActor
    private func listenForForcedUpdateStatusChanges() {
        guard let forcedUpdateModalDelegate = AppSubsystem.delegates.forcedUpdateModal else { return }
        forcedUpdateModalDelegate
            .forcedUpdateRequiredPublisher
            .filter { $0 } // Only pass through `true`
            .prefix(1) // Automatically cancel after the first `true`
            .receive(on: DispatchQueue.main)
            .sink { _ in
                BuildExpiryAlert.shared.dismiss(triggerBuildExpiryOverride: false)
                RootWindowStatus.shared.rootView = .forcedUpdateModalPage
            }
            .store(in: &cancellables)
    }
}

/* MARK: Date Formatter Dependencies */

private enum BuildSKUDateFormatterDependency: DependencyKey {
    static func resolve(_: DependencyValues) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "ddMMyy"
        formatter.locale = .init(identifier: "en_US_POSIX")
        return formatter
    }
}

private enum ExpiryInfoStringDateFormatterDependency: DependencyKey {
    static func resolve(_: DependencyValues) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = .init(identifier: "en_US_POSIX")
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
}
