//
//  Callback.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public enum Callback<Success, Failure> where Failure: Exceptionable {
    case success(Success)
    case failure(Failure)
}

public protocol Exceptionable {
    var code: String { get }
    var descriptor: String { get }
    var isReportable: Bool { get }
    var metadata: ExceptionMetadata { get }
    var underlyingExceptions: [Exception]? { get }
    var userInfo: [String: Any]? { get }
}

public extension Callback {
    func get() throws -> Success {
        switch self {
        case let .success(success):
            return success

        case let .failure(exceptionable):
            let exception: Exception = .init(
                exceptionable.descriptor,
                isReportable: exceptionable.isReportable,
                userInfo: exceptionable.userInfo,
                underlyingExceptions: exceptionable.underlyingExceptions,
                metadata: exceptionable.metadata
            )

            throw exception
        }
    }
}
