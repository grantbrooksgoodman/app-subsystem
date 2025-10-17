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
    public var description: String {
        get { userFacingDescriptor }
        set { descriptor = newValue }
    }

    public var id: String { "\(code)\(metadata.id)".lowercased() }
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
    public static var errorDomain: String { "exception" }

    public var errorCode: Int { Int(code) ?? 0 }
    public var errorUserInfo: [String: Any] { userInfo ?? [:] }
}

extension Exception: LocalizedError {
    public var errorDescription: String? { descriptor }
}

public extension Exception {
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

    static func internetConnectionOffline(metadata: ExceptionMetadata) -> Exception {
        .init(
            "Internet connection is offline.",
            isReportable: false,
            userInfo: [
                CommonParameter.userFacingDescriptor.rawValue: AppSubsystem.delegates.localizedStrings.internetConnectionOffline,
            ],
            metadata: metadata
        )
    }

    static func timedOut(metadata: ExceptionMetadata) -> Exception {
        .init(
            "The operation timed out. Please try again later.",
            isReportable: false,
            userInfo: [
                CommonParameter.userFacingDescriptor.rawValue: AppSubsystem.delegates.localizedStrings.timedOut,
            ],
            metadata: metadata
        )
    }
}
