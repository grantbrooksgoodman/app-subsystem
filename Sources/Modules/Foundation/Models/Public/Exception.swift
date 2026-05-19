//
//  Exception.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import CryptoKit
import Foundation

/// A structured error type that captures a human-readable description,
/// a deterministic error code, source-location metadata, and an
/// optional chain of underlying exceptions.
///
/// Use `Exception` throughout your app as the standard error
/// currency. Each exception records where it was created, what went
/// wrong, and whether it should be reported to crash-reporting
/// infrastructure:
///
/// ```swift
/// guard let data else {
///     throw Exception(
///         "Failed to load configuration file.",
///         metadata: .init(sender: self)
///     )
/// }
/// ```
///
/// ## Error Codes
///
/// Every exception carries a ``code`` derived from a SHA-256 hash of
/// its descriptor. This produces a short, deterministic identifier
/// that remains stable across builds for any given descriptor string.
/// You can also supply a static code through the `userInfo` dictionary
/// when you need a fixed value.
///
/// ## User-Facing Descriptors
///
/// The ``userFacingDescriptor`` property returns a localized,
/// end-user-appropriate message. On general-release builds, if no
/// user-facing descriptor has been registered through the
/// ``AppSubsystem/Delegates/ExceptionMetadataDelegate``, a generic
/// "something went wrong" string is returned instead of the
/// developer-facing descriptor.
///
/// ## Underlying Exceptions
///
/// Exceptions can form a chain through ``underlyingExceptions``.
/// Reading this property recursively traverses the entire chain,
/// returning a flat array of every exception in the hierarchy.
///
/// - SeeAlso: ``ExceptionMetadata``, ``Exceptionable``,
///   ``Callback``, ``AppException``
public struct Exception: Equatable, Exceptionable, Swift.Error, @unchecked Sendable {
    // MARK: - Types

    enum UserInfo: String {
        case descriptor = "Descriptor"
        case errorCode = "ErrorCode"
        case nsErrorCode = "NSErrorCode"
        case nsErrorDomain = "NSErrorDomain"
        case nsLocalizedDescription = "NSLocalizedDescription"
        case staticErrorCode = "StaticErrorCode"
        case userFacingDescriptor = "UserFacingDescriptor"
    }

    // MARK: - Properties

    /// A short, deterministic error code derived from the descriptor.
    public let code: String

    /// A Boolean value that indicates whether this exception should be
    /// reported to crash-reporting or analytics infrastructure.
    public let isReportable: Bool

    /// The source-location metadata captured at the point of creation.
    public let metadata: ExceptionMetadata

    /// An optional dictionary of supplementary information attached to
    /// the exception.
    public let userInfo: [String: Any]?

    private let _descriptor = LockIsolated<String>("")
    private let _underlyingExceptions = LockIsolated<[Exception]?>(nil)

    // MARK: - Computed Properties

    /// A developer-facing description of what went wrong.
    public internal(set) var descriptor: String {
        get { _descriptor.wrappedValue }
        set { _descriptor.wrappedValue = newValue }
    }

    /// The full chain of underlying exceptions, recursively traversed.
    ///
    /// When read, this property walks the entire underlying exception
    /// hierarchy and returns a flat array containing every exception
    /// in the chain.
    public private(set) var underlyingExceptions: [Exception]? {
        get { traversedUnderlyingExceptions }
        set { _underlyingExceptions.wrappedValue = newValue }
    }

    /// A localized, end-user-appropriate description of the error.
    ///
    /// The value is resolved in the following order:
    /// 1. A `"UserFacingDescriptor"` entry in ``userInfo``.
    /// 2. A mapping provided by the
    ///    ``AppSubsystem/Delegates/ExceptionMetadataDelegate``.
    /// 3. On general-release builds, a generic localized string. On
    ///    pre-release builds, the raw ``descriptor``.
    public var userFacingDescriptor: String {
        @Dependency(\.build) var build: Build

        if let userFacingDescriptor = userInfo?[
            UserInfo.userFacingDescriptor.rawValue
        ] as? String ?? AppSubsystem
            .delegates
            .exceptionMetadata?
            .userFacingDescriptor(for: descriptor) {
            return userFacingDescriptor
        }

        return build.milestone == .generalRelease
            ? Localized(SubsystemStringKey.somethingWentWrong).wrappedValue
            : descriptor
    }

    /// The recursively traversed value of all underlying `Exception`s for this instance.
    private var traversedUnderlyingExceptions: [Exception]? {
        _underlyingExceptions.projectedValue.withValue {
            guard let underlyingExceptions = $0 else { return nil }
            var allExceptions = underlyingExceptions
            for underlyingException in underlyingExceptions {
                allExceptions.append(
                    contentsOf: underlyingException.traversedUnderlyingExceptions ?? []
                )
            }
            return allExceptions
        }
    }

    // MARK: - Init

    /// Creates an exception with the given descriptor.
    ///
    /// The error ``code`` is derived automatically from the descriptor
    /// unless a `"StaticErrorCode"` key is present in `userInfo`.
    /// When `isReportable` is `nil`, the value is resolved through
    /// the ``AppSubsystem/Delegates/ExceptionMetadataDelegate``,
    /// falling back to `true` if no delegate is registered.
    ///
    /// - Parameters:
    ///   - descriptor: A developer-facing description. The default is
    ///     `"An unknown error occurred."`.
    ///   - isReportable: Whether the exception can be reported, or
    ///     `nil` to resolve automatically.
    ///   - userInfo: An optional dictionary of supplementary
    ///     information.
    ///   - underlyingExceptions: An optional array of exceptions that
    ///     caused this one.
    ///   - metadata: The source-location metadata for this exception.
    public init(
        _ descriptor: String = "An unknown error occurred.",
        isReportable: Bool? = nil,
        userInfo: [String: Any]? = nil,
        underlyingExceptions: [Exception]? = nil,
        metadata: ExceptionMetadata
    ) {
        let errorCode = (userInfo?[UserInfo.staticErrorCode.rawValue] as? String) ?? descriptor.errorCode
        code = errorCode

        self.isReportable = isReportable ?? AppSubsystem.delegates.exceptionMetadata?.isReportable(errorCode) ?? true
        self.metadata = metadata
        self.userInfo = userInfo?.isEmpty == false ? userInfo!.withCapitalizedKeys : nil

        self.descriptor = descriptor
        self.underlyingExceptions = underlyingExceptions?.isEmpty == false ? underlyingExceptions!.unique.filter { $0 != self } : nil
    }

    /// Creates an exception from a Swift `Error`.
    ///
    /// The error is bridged to `NSError` and its domain, code, and
    /// user info are captured automatically.
    ///
    /// - Parameters:
    ///   - error: The error to wrap.
    ///   - isReportable: Whether the exception can be reported, or
    ///     `nil` to resolve automatically.
    ///   - userInfo: Additional supplementary information to merge.
    ///   - underlyingExceptions: An optional array of exceptions that
    ///     caused this one.
    ///   - metadata: The source-location metadata for this exception.
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

    /// Creates an exception from an `NSError`.
    ///
    /// The error's `domain`, `code`, `localizedDescription`, and
    /// `userInfo` are captured into the exception's properties. The
    /// `NSLocalizedDescription` key is filtered from the merged user
    /// info to avoid redundancy with the ``descriptor``.
    ///
    /// - Parameters:
    ///   - error: The `NSError` to wrap.
    ///   - isReportable: Whether the exception can be reported, or
    ///     `nil` to resolve automatically.
    ///   - userInfo: Additional supplementary information to merge.
    ///   - underlyingExceptions: An optional array of exceptions that
    ///     caused this one.
    ///   - metadata: The source-location metadata for this exception.
    public init(
        _ error: NSError,
        isReportable: Bool? = nil,
        userInfo: [String: Any]? = nil,
        underlyingExceptions: [Exception]? = nil,
        metadata: ExceptionMetadata
    ) {
        let errorCode = error.staticIdentifier.errorCode
        code = errorCode

        self.isReportable = isReportable ?? AppSubsystem.delegates.exceptionMetadata?.isReportable(errorCode) ?? true
        self.metadata = metadata

        var concatenatedUserInfo: [String: Any] = error.userInfo.filter { $0.key != UserInfo.nsLocalizedDescription.rawValue }
        concatenatedUserInfo[UserInfo.nsErrorCode.rawValue] = error.code
        concatenatedUserInfo[UserInfo.nsErrorDomain.rawValue] = error.domain

        if let userInfo,
           !userInfo.isEmpty {
            concatenatedUserInfo.merge(
                userInfo.filter { $0.key != UserInfo.nsLocalizedDescription.rawValue },
                uniquingKeysWith: { $1 }
            )
        }

        concatenatedUserInfo[UserInfo.staticErrorCode.rawValue] = errorCode
        self.userInfo = concatenatedUserInfo.isEmpty ? nil : concatenatedUserInfo.withCapitalizedKeys

        descriptor = error.localizedDescription
        self.underlyingExceptions = underlyingExceptions?.isEmpty == false ? underlyingExceptions!.unique.filter { $0 != self } : nil
    }

    // MARK: - Append

    /// Returns a new exception with the given entries merged into its
    /// user info dictionary.
    ///
    /// Existing keys are overwritten by entries in the provided
    /// dictionary.
    ///
    /// - Parameter userInfo: The entries to merge.
    ///
    /// - Returns: A new exception with the merged user info.
    public func appending(userInfo: [String: Any]) -> Exception {
        guard !userInfo.isEmpty else { return self }
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

    /// Returns a new exception with the given exception appended to
    /// its underlying exception chain.
    ///
    /// - Parameter underlyingException: The exception to append.
    ///
    /// - Returns: A new exception with the extended chain.
    public func appending(underlyingException: Exception) -> Exception {
        _underlyingExceptions.projectedValue.withValue {
            guard var currentUnderlyingExceptions = $0,
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
    }

    // MARK: - AppException Equality Comparison

    /// Returns a Boolean value indicating whether this exception's
    /// error code matches a catalogued ``AppException``.
    ///
    /// - Parameter cataloggedException: The catalogued exception to
    ///   compare against.
    ///
    /// - Returns: `true` if the codes match; otherwise, `false`.
    public func isEqual(to cataloguedException: AppException) -> Bool {
        code == cataloguedException.errorCode
    }

    /// Returns a Boolean value indicating whether this exception's
    /// error code matches any catalogued ``AppException``.
    ///
    /// - Parameter in: An array of ``AppException`` values to compare
    ///   against.
    ///
    /// - Returns: `true` if a match is found; otherwise, `false`.
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

        let stopWords: Set = [
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
