//
//  Build.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Combine
import Foundation

/// The build configuration for the current app, including
/// version information, milestone, expiry, and runtime diagnostics.
///
/// `Build` is created once during ``AppSubsystem`` initialization and
/// is available through the dependency system:
///
/// ```swift
/// @Dependency(\.build) var build: Build
/// ```
///
/// It exposes both static metadata – such as the code name, milestone,
/// and App Store build number – and dynamic properties that are
/// derived at runtime, including the build SKU, bundle revision,
/// expiry date, and network reachability status.
///
/// ## Milestones
///
/// Every build belongs to a ``Milestone`` that indicates its
/// position in the release cycle. Certain subsystem behaviors –
/// such as Developer Mode availability and timebomb enforcement –
/// are gated on the current milestone.
///
/// ## Build Expiry
///
/// Prerelease builds include a 30-day timebomb that requires
/// entry of an expiration override code after the evaluation period
/// ends. The ``expiryDate``, ``isTimebombActive``, and
/// ``expirationOverrideCode`` properties support this mechanism.
/// General-release builds are exempt from expiry.
///
/// - SeeAlso: ``BuildDependency``
public final class Build: @unchecked Sendable {
    // MARK: - Types

    /// The release cycle stage of a build.
    ///
    /// Each milestone has a single-character ``shortString``
    /// representation used in build SKUs and bundle version
    /// identifiers.
    public enum Milestone: String {
        /* MARK: Cases */

        /// A very early development build.
        /// Typically builds 0-1500.
        case preAlpha = "pre-alpha"

        /// An early development build with core features in
        /// progress.
        /// Typically builds 1,500 to 3,000.
        case alpha

        /// A feature-complete build undergoing testing.
        /// Typically builds 3,000 to 6,000.
        case beta

        /// A build that is a candidate for general release.
        /// Typically builds 6,000 onwards.
        case releaseCandidate = "release candidate"

        /// A production release distributed through the App Store.
        case generalRelease = "general"

        /* MARK: Properties */

        /// A single-character abbreviation for this milestone.
        ///
        /// The abbreviation is appended to build numbers and SKUs
        /// to indicate the milestone (for example, `"b"` for beta).
        public var shortString: String {
            switch self {
            case .preAlpha: "p"
            case .alpha: "a"
            case .beta: "b"
            case .releaseCandidate: "c"
            case .generalRelease: "g"
            }
        }
    }

    // MARK: - Dependencies

    @Dependency(\.buildSKUDateFormatter) private var buildSKUDateFormatter: DateFormatter
    @Dependency(\.currentCalendar) private var calendar: Calendar
    @Dependency(\.expiryInfoStringDateFormatter) private var expiryInfoStringDateFormatter: DateFormatter
    @Dependency(\.mainBundle) private var mainBundle: Bundle

    // MARK: - Properties

    /// The build number of the most recent App Store release.
    ///
    /// This value is used to compute the ``revisionBuildNumber`` and
    /// ``bundleRevision``.
    public let appStoreBuildNumber: Int

    /// The internal code name for the current release.
    public let codeName: String

    /// The public-facing product name used in general-release builds.
    public let finalName: String

    /// A Boolean value that indicates whether logging is enabled for
    /// this build.
    public let loggingEnabled: Bool

    /// The release cycle stage of this build.
    public let milestone: Milestone

    private let _cancellables = LockIsolated<Set<AnyCancellable>>([])

    // MARK: - Computed Properties

    /// The major version number extracted from the bundle version
    /// string.
    public var appStoreReleaseVersion: Int { getAppStoreReleaseVersion() }

    /// The build number read from the bundle's `CFBundleVersion`.
    public var buildNumber: Int { getBuildNumber() }

    /// A unique SKU string that encodes the build date, a
    /// three-letter code-name abbreviation, the build number, and
    /// the milestone.
    public var buildSKU: String { getBuildSKU() }

    /// The short bundle version string (for example, `"1.2.3"`).
    public var bundleVersion: String { getBundleVersion() }

    /// An alphabetic revision identifier derived from the number of
    /// builds since the last App Store release.
    public var bundleRevision: String { getBundleRevision() }

    /// The six-digit code required to override build expiry.
    ///
    /// The code is derived deterministically from the code name.
    public var expirationOverrideCode: String { getExpirationOverrideCode() }

    /// The date on which this build's evaluation period ends.
    ///
    /// The expiry date is 30 days after the build date.
    public var expiryDate: Date { getExpiryDate() }

    /// A human-readable string describing the build's expiry status.
    public var expiryInfoString: String { getExpiryInfoString() }

    /// A Boolean value that indicates whether Developer Mode is
    /// enabled.
    ///
    /// Developer mode is always disabled in general-release builds.
    public var isDeveloperModeEnabled: Bool { getIsDeveloperModeEnabled() }

    /// A Boolean value that indicates whether the device currently
    /// has network connectivity.
    public var isOnline: Bool { getNetworkStatus() }

    /// A Boolean value that indicates whether the build expiry
    /// timebomb is active.
    ///
    /// The timebomb is always inactive in general-release builds.
    public var isTimebombActive: Bool { getIsTimebombActive() }

    /// A deterministic, alphanumeric project identifier derived from
    /// the code name and first compile date.
    public var projectID: String { getProjectID() }

    /// The number of builds since the last App Store release.
    public var revisionBuildNumber: Int { getRevisionBuildNumber() }

    private var buildDateUnixDouble: TimeInterval {
        getBuildDateUnixDouble()
    }

    private var cancellables: Set<AnyCancellable> {
        get { _cancellables.wrappedValue }
        set { _cancellables.wrappedValue = newValue }
    }

    private var firstCompileDate: Date {
        getFirstCompileDate()
    }

    private var infoDictionary: [String: Any] {
        mainBundle.infoDictionary ?? [:]
    }

    // MARK: - Init

    init(
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
