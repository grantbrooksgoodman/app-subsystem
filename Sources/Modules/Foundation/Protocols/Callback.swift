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
    var descriptor: String { get }
    var extraParams: [String: Any]? { get }
    var hashlet: String! { get }
    var isReportable: Bool { get }
    var metadata: [Any] { get }
    var metaID: String! { get }
    var underlyingExceptions: [Exception]? { get }
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
                extraParams: exceptionable.extraParams,
                underlyingExceptions: exceptionable.underlyingExceptions,
                metadata: exceptionable.metadata
            )

            Logger.log(exception)
            guard let hashlet = exception.hashlet else { throw _Failure.exceptionDescriptor(exception.descriptor) }
            throw _Failure.exceptionDescriptor("\(exception.descriptor) (\(hashlet))")
        }
    }
}

private enum _Failure: LocalizedError {
    // MARK: - Cases

    case exceptionDescriptor(String)

    // MARK: - Properties

    var errorDescription: String? {
        switch self {
        case let .exceptionDescriptor(descriptor): return descriptor
        }
    }
}
