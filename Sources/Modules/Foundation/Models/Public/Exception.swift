//
//  Exception.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import CryptoKit
import Foundation

public struct Exception: Equatable, Exceptionable {
    // MARK: - Types

    public enum CommonParamKeys: String {
        case userFacingDescriptor = "UserFacingDescriptor"
    }

    // MARK: - Properties

    // Array
    public var metadata: [Any]
    public var underlyingExceptions: [Exception]?

    // String
    public var descriptor: String
    public var hashlet: String!
    public var metaID: String!

    // Other
    public var extraParams: [String: Any]?
    public var isReportable: Bool

    // MARK: - Computed Properties

    /// The recursively traversed value of all underlying `Exception`s for this instance.
    public var traversedUnderlyingExceptions: [Exception] {
        guard let underlyingExceptions else { return [] }
        var allExceptions = underlyingExceptions
        underlyingExceptions.forEach { allExceptions.append(contentsOf: $0.traversedUnderlyingExceptions) }
        return allExceptions
    }

    public var userFacingDescriptor: String {
        @Dependency(\.build) var build: Build

        if let params = extraParams,
           let laymanDescriptor = params[CommonParamKeys.userFacingDescriptor.rawValue] as? String {
            return laymanDescriptor
        }

        guard let descriptor = AppSubsystem.delegates.exceptionMetadata?.userFacingDescriptor(for: descriptor) else {
            return build.milestone == .generalRelease ? (AppSubsystem.delegates.localizedStrings.somethingWentWrong) : descriptor
        }

        return descriptor
    }

    // MARK: - Init

    public init(
        _ descriptor: String = "An unknown error occurred.",
        isReportable: Bool? = nil,
        extraParams: [String: Any]? = nil,
        underlyingExceptions: [Exception]? = nil,
        metadata: [Any]
    ) {
        guard metadata.isValidMetadata else { fatalError("Improperly formatted metadata") }

        self.descriptor = descriptor
        self.isReportable = true // Set initial value.
        self.extraParams = extraParams
        self.metadata = metadata

        if let staticHashlet = extraParams?["StaticHashlet"] as? String {
            hashlet = staticHashlet
        } else {
            guard let hashlet = getHashlet(for: self.descriptor) else { fatalError("Failed to generate hashlet") }
            self.hashlet = hashlet
        }

        self.isReportable = isReportable ?? AppSubsystem.delegates.exceptionMetadata?.isReportable(hashlet) ?? true
        metaID = getMetaID(for: metadata)
        self.underlyingExceptions = underlyingExceptions?.unique.filter { $0 != self }
    }

    public init(
        _ error: Error,
        isReportable: Bool? = nil,
        extraParams: [String: Any]? = nil,
        underlyingExceptions: [Exception]? = nil,
        metadata: [Any]
    ) {
        self.init(
            error as NSError,
            isReportable: isReportable,
            extraParams: extraParams,
            underlyingExceptions: underlyingExceptions,
            metadata: metadata
        )
    }

    public init(
        _ error: NSError,
        isReportable: Bool? = nil,
        extraParams: [String: Any]? = nil,
        underlyingExceptions: [Exception]? = nil,
        metadata: [Any]
    ) {
        guard metadata.isValidMetadata else { fatalError("Improperly formatted metadata") }

        descriptor = error.localizedDescription
        self.isReportable = true // Set initial value.
        self.metadata = metadata

        var params: [String: Any] = error.userInfo.filter { $0.key != "NSLocalizedDescription" }
        params["NSErrorCode"] = error.code
        params["NSErrorDomain"] = error.domain

        if let extraParams,
           !extraParams.isEmpty {
            for param in extraParams {
                guard param.key != "NSLocalizedDescription" else { continue }
                params[param.key] = param.value
            }
        }

        guard let hashlet = getHashlet(for: error.staticIdentifier) else { fatalError("Failed to generate hashlet") }
        self.hashlet = hashlet
        self.isReportable = isReportable ?? AppSubsystem.delegates.exceptionMetadata?.isReportable(hashlet) ?? true
        metaID = getMetaID(for: metadata)

        params["StaticHashlet"] = self.hashlet
        self.extraParams = params.withCapitalizedKeys

        self.underlyingExceptions = underlyingExceptions?.unique.filter { $0 != self }
    }

    // MARK: - Append

    public func appending(extraParams: [String: Any]) -> Exception {
        guard let currentParams = self.extraParams,
              !currentParams.isEmpty else {
            return .init(
                descriptor,
                isReportable: isReportable,
                extraParams: extraParams.withCapitalizedKeys,
                metadata: metadata
            )
        }

        var params: [String: Any] = currentParams
        extraParams.forEach { params[$0.key] = $0.value }

        return .init(
            descriptor,
            isReportable: isReportable,
            extraParams: params.withCapitalizedKeys,
            metadata: metadata
        )
    }

    public func appending(underlyingException: Exception) -> Exception {
        guard let currentUnderlyingExceptions = underlyingExceptions,
              !currentUnderlyingExceptions.isEmpty else {
            return .init(
                descriptor,
                isReportable: isReportable,
                extraParams: extraParams,
                underlyingExceptions: [underlyingException],
                metadata: metadata
            )
        }

        var exceptions = currentUnderlyingExceptions
        exceptions.append(underlyingException)

        return .init(
            descriptor,
            isReportable: isReportable,
            extraParams: extraParams,
            underlyingExceptions: exceptions,
            metadata: metadata
        )
    }

    // MARK: - AppException Equality Comparison

    public func isEqual(to cataloggedException: AppException) -> Bool {
        hashlet == cataloggedException.hashletValue
    }

    public func isEqual(toAny in: [AppException]) -> Bool {
        !`in`.filter { $0.hashletValue == hashlet }.isEmpty
    }

    // MARK: - Equatable Conformance

    public static func == (left: Exception, right: Exception) -> Bool {
        let leftMetaID = left.metaID
        let leftHashlet = left.hashlet
        let leftDescriptor = left.descriptor
        let leftIsReportable = left.isReportable
        let leftUnderlyingExceptions = left.underlyingExceptions
        let leftTraversedUnderlyingExceptions = left.traversedUnderlyingExceptions

        let rightMetaID = right.metaID
        let rightHashlet = right.hashlet
        let rightDescriptor = right.descriptor
        let rightIsReportable = right.isReportable
        let rightUnderlyingExceptions = right.underlyingExceptions
        let rightTraversedUnderlyingExceptions = right.traversedUnderlyingExceptions

        var leftStringBasedParams = [String: String]()
        left.extraParams?.forEach { parameter in
            if let stringValue = parameter.value as? String {
                leftStringBasedParams[parameter.key] = stringValue
            }
        }

        var rightStringBasedParams = [String: String]()
        right.extraParams?.forEach { parameter in
            if let stringValue = parameter.value as? String {
                rightStringBasedParams[parameter.key] = stringValue
            }
        }

        let leftNonStringBasedParamsCount = (left.extraParams?.count ?? 0) - leftStringBasedParams.count
        let rightNonStringBasedParamsCount = (right.extraParams?.count ?? 0) - rightStringBasedParams.count

        guard leftMetaID == rightMetaID,
              leftHashlet == rightHashlet,
              leftDescriptor == rightDescriptor,
              leftIsReportable == rightIsReportable,
              leftUnderlyingExceptions == rightUnderlyingExceptions,
              leftTraversedUnderlyingExceptions == rightTraversedUnderlyingExceptions,
              leftStringBasedParams == rightStringBasedParams,
              leftNonStringBasedParamsCount == rightNonStringBasedParamsCount else { return false }

        return true
    }

    // MARK: - Auxiliary

    private func getHashlet(for descriptor: String) -> String? {
        var hashlet = ""

        let stripWords = ["a", "an", "is", "that", "the", "this", "was"]
        for word in descriptor.components(separatedBy: " ") where !stripWords.contains(word.lowercased()) {
            hashlet.append("\(word)\(word.lowercased() == "not" ? "" : " ")")
        }

        let alphabetSet = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
        hashlet = hashlet.filter { alphabetSet.contains($0) }

        hashlet = hashlet.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        hashlet = hashlet.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\u{00A0}", with: "")
        hashlet = SHA256.hash(data: Data(hashlet.utf8)).compactMap { String(format: "%02x", $0) }.joined()

        guard !hashlet.isEmpty,
              hashlet.count > 2 else { return nil }

        let count = hashlet.components.count
        let prefix = hashlet.components[0 ... 1]
        let suffix = hashlet.components[count - 2 ... count - 1]

        return "\(prefix.joined())\(suffix.joined())".uppercased()
    }

    private func getMetaID(for metadata: [Any]) -> String {
        // swiftlint:disable force_cast
        let unformattedFileName = metadata[1] as! String
        let fileName = unformattedFileName.components(separatedBy: "/").last!.components(separatedBy: ".")[0]
        let lineNumber = metadata[3] as! Int
        // swiftlint:enable force_cast

        var hexChars = [String]()

        for character in fileName {
            guard let asciiValue = character.asciiValue else { continue }
            hexChars.append(.init(format: "%02X", asciiValue))
        }

        if hexChars.count > 3 {
            var subsequence = Array(hexChars[0 ... 3])
            subsequence.append(hexChars.last!)
            hexChars = subsequence
        }

        return "\(hexChars.joined())x\(lineNumber)".lowercased()
    }
}
