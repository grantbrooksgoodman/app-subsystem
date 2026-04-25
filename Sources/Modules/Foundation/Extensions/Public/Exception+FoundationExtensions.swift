//
//  Exception+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/* Proprietary */
import AlertKit

extension Exception: AlertKit.Errorable {
    /// The user-facing descriptor of this exception.
    public var description: String {
        get { userFacingDescriptor }
        set { descriptor = newValue }
    }

    /// A lowercased identifier combining the error code and metadata
    /// ID.
    public var id: String {
        "\(code)\(metadata.id)".lowercased()
    }

    /// An array of the exception's metadata values for AlertKit
    /// display.
    public var metadataArray: [Any] {
        [
            metadata.sender,
            metadata.fileName,
            metadata.function,
            metadata.line,
        ]
    }
}

extension Exception: CustomNSError {
    /// The error domain for all exceptions.
    public static var errorDomain: String { "exception" }

    /// The error code. Always `0`.
    public var errorCode: Int { 0 }

    /// The exception's user info dictionary, or an empty dictionary.
    public var errorUserInfo: [String: Any] { userInfo ?? [:] }
}

extension Exception: LocalizedError {
    /// The developer-facing descriptor of this exception.
    public var errorDescription: String? { descriptor }
}

public extension Exception {
    /// Creates an exception from an optional error, using a generic
    /// descriptor when the error is `nil`.
    init(
        _ error: Error?,
        metadata: ExceptionMetadata
    ) {
        guard let error else {
            self.init(metadata: metadata)
            return
        }

        self.init(
            error,
            metadata: metadata
        )
    }

    /// Returns a non-reportable exception indicating the internet
    /// connection is offline.
    static func internetConnectionOffline(metadata: ExceptionMetadata) -> Exception {
        .init(
            "Internet connection is offline.",
            isReportable: false,
            userInfo: [
                UserInfo.userFacingDescriptor.rawValue: Localized(SubsystemStringKey.internetConnectionOffline).wrappedValue,
            ],
            metadata: metadata
        )
    }

    /// Returns a non-reportable exception indicating the operation
    /// timed out.
    static func timedOut(metadata: ExceptionMetadata) -> Exception {
        .init(
            "The operation timed out. Please try again later.",
            isReportable: false,
            userInfo: [
                UserInfo.userFacingDescriptor.rawValue: Localized(SubsystemStringKey.timedOut).wrappedValue,
            ],
            metadata: metadata
        )
    }
}
