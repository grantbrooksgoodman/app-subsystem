//
//  Exception.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import CryptoKit
import Foundation

public struct Exception: Equatable, Exceptionable, Swift.Error {
    // MARK: - Types

    enum CommonParameter: String {
        case descriptor = "Descriptor"
        case errorCode = "ErrorCode"
        case nsErrorCode = "NSErrorCode"
        case nsErrorDomain = "NSErrorDomain"
        case nsLocalizedDescription = "NSLocalizedDescription"
        case staticErrorCode = "StaticErrorCode"
        case userFacingDescriptor = "UserFacingDescriptor"
    }

    // MARK: - Properties

    public let code: String
    public let isReportable: Bool
    public let metadata: ExceptionMetadata
    public let userInfo: [String: Any]?

    public internal(set) var descriptor: String

    public private(set) var underlyingExceptions: [Exception]? {
        get { traversedUnderlyingExceptions }
        set { _underlyingExceptions = newValue }
    }

    private var _underlyingExceptions: [Exception]?

    // MARK: - Computed Properties

    public var userFacingDescriptor: String {
        @Dependency(\.build) var build: Build

        if let userFacingDescriptor = userInfo?[CommonParameter.userFacingDescriptor.rawValue] as? String {
            return userFacingDescriptor
        }

        guard let descriptor = AppSubsystem.delegates.exceptionMetadata?.userFacingDescriptor(for: descriptor) else {
            return build.milestone == .generalRelease ? (AppSubsystem.delegates.localizedStrings.somethingWentWrong) : descriptor
        }

        return descriptor
    }

    /// The recursively traversed value of all underlying `Exception`s for this instance.
    private var traversedUnderlyingExceptions: [Exception]? {
        guard let underlyingExceptions = _underlyingExceptions else { return nil }
        var allExceptions = underlyingExceptions
        underlyingExceptions.forEach { allExceptions.append(contentsOf: $0.traversedUnderlyingExceptions ?? []) }
        return allExceptions
    }

    // MARK: - Init

    public init(
        _ descriptor: String = "An unknown error occurred.",
        isReportable: Bool? = nil,
        userInfo: [String: Any]? = nil,
        underlyingExceptions: [Exception]? = nil,
        metadata: ExceptionMetadata
    ) {
        let errorCode = (userInfo?[CommonParameter.staticErrorCode.rawValue] as? String) ?? descriptor.errorCode
        code = errorCode

        self.descriptor = descriptor
        self.isReportable = isReportable ?? AppSubsystem.delegates.exceptionMetadata?.isReportable(errorCode) ?? true
        self.metadata = metadata
        self.userInfo = userInfo?.isEmpty == false ? userInfo!.withCapitalizedKeys : nil

        self.underlyingExceptions = underlyingExceptions?.isEmpty == false ? underlyingExceptions!.unique.filter { $0 != self } : nil
    }

    public init(
        _ error: Error,
        isReportable: Bool? = nil,
        userInfo: [String: Any]? = nil,
        underlyingExceptions: [Exception]? = nil,
        metadata: ExceptionMetadata
    ) {
        self.init(
            error as NSError,
            isReportable: isReportable,
            userInfo: userInfo,
            underlyingExceptions: underlyingExceptions,
            metadata: metadata
        )
    }

    public init(
        _ error: NSError,
        isReportable: Bool? = nil,
        userInfo: [String: Any]? = nil,
        underlyingExceptions: [Exception]? = nil,
        metadata: ExceptionMetadata
    ) {
        let errorCode = error.staticIdentifier.errorCode
        code = errorCode

        descriptor = error.localizedDescription
        self.isReportable = isReportable ?? AppSubsystem.delegates.exceptionMetadata?.isReportable(errorCode) ?? true
        self.metadata = metadata

        var concatenatedUserInfo: [String: Any] = error.userInfo.filter { $0.key != CommonParameter.nsLocalizedDescription.rawValue }
        concatenatedUserInfo[CommonParameter.nsErrorCode.rawValue] = error.code
        concatenatedUserInfo[CommonParameter.nsErrorDomain.rawValue] = error.domain

        if let userInfo,
           !userInfo.isEmpty {
            concatenatedUserInfo.merge(
                userInfo.filter { $0.key != CommonParameter.nsLocalizedDescription.rawValue },
                uniquingKeysWith: { $1 }
            )
        }

        concatenatedUserInfo[CommonParameter.staticErrorCode.rawValue] = errorCode
        self.userInfo = concatenatedUserInfo.isEmpty ? nil : concatenatedUserInfo.withCapitalizedKeys

        self.underlyingExceptions = underlyingExceptions?.isEmpty == false ? underlyingExceptions!.unique.filter { $0 != self } : nil
    }

    // MARK: - Append

    public func appending(userInfo: [String: Any]) -> Exception {
        guard var currentUserInfo = self.userInfo,
              !currentUserInfo.isEmpty else {
            return .init(
                descriptor,
                isReportable: isReportable,
                userInfo: userInfo.withCapitalizedKeys,
                underlyingExceptions: underlyingExceptions,
                metadata: metadata
            )
        }

        userInfo.forEach { currentUserInfo[$0.key] = $0.value }
        return .init(
            descriptor,
            isReportable: isReportable,
            userInfo: currentUserInfo.withCapitalizedKeys,
            underlyingExceptions: underlyingExceptions,
            metadata: metadata
        )
    }

    public func appending(underlyingException: Exception) -> Exception {
        guard var currentUnderlyingExceptions = _underlyingExceptions,
              !currentUnderlyingExceptions.isEmpty else {
            return .init(
                descriptor,
                isReportable: isReportable,
                userInfo: userInfo,
                underlyingExceptions: [underlyingException],
                metadata: metadata
            )
        }

        currentUnderlyingExceptions.append(underlyingException)
        return .init(
            descriptor,
            isReportable: isReportable,
            userInfo: userInfo,
            underlyingExceptions: currentUnderlyingExceptions,
            metadata: metadata
        )
    }

    // MARK: - AppException Equality Comparison

    public func isEqual(to cataloggedException: AppException) -> Bool {
        code == cataloggedException.errorCode
    }

    public func isEqual(toAny in: [AppException]) -> Bool {
        !`in`.filter { $0.errorCode == code }.isEmpty
    }

    // MARK: - Equatable Conformance

    public static func == (left: Exception, right: Exception) -> Bool {
        let sameCode = left.code == right.code
        let sameDescriptor = left.descriptor == right.descriptor
        let sameIsReportable = left.isReportable == right.isReportable
        let sameMetadata = AnyHashable(left.metadata) == AnyHashable(right.metadata)
        let sameUnderlyingExceptions = left.underlyingExceptions == right.underlyingExceptions

        let leftStringBasedUserInfo = left.userInfo?.compactMapValues { $0 as? String }
        let rightStringBasedUserInfo = right.userInfo?.compactMapValues { $0 as? String }

        let leftNonStringBasedUserInfoCount = (left.userInfo?.count ?? 0) - (leftStringBasedUserInfo?.count ?? 0)
        let rightNonStringBasedUserInfoCount = (right.userInfo?.count ?? 0) - (rightStringBasedUserInfo?.count ?? 0)

        let sameStringBasedUserInfo = leftStringBasedUserInfo == rightStringBasedUserInfo
        let sameNonStringBasedUserInfoCount = leftNonStringBasedUserInfoCount == rightNonStringBasedUserInfoCount

        guard sameCode,
              sameDescriptor,
              sameIsReportable,
              sameMetadata,
              sameUnderlyingExceptions,
              sameStringBasedUserInfo,
              sameNonStringBasedUserInfoCount else { return false }

        return true
    }
}

private extension String {
    var errorCode: String {
        guard !isEmpty else { return "0000" }

        let stopWords: Set<String> = [
            "a",
            "an",
            "is",
            "that",
            "the",
            "this",
            "was",
        ]

        let joinedWords = split(separator: " ")
            .filter { !stopWords.contains($0.lowercased()) }
            .joined()

        let lettersOnly = joinedWords.replacingOccurrences(
            of: "[^A-Za-z]",
            with: "",
            options: .regularExpression
        ).lowercased()

        let dataDigest = SHA256.hash(data: Data(lettersOnly.utf8))
        let hexString = dataDigest.map { String(format: "%02x", $0) }.joined()
        return (hexString.prefix(2) + hexString.suffix(2)).uppercased()
    }
}
