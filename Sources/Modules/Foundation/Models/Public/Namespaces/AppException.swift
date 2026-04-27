//
//  AppException.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A catalogued error code that can be compared against live
/// ``Exception`` instances.
///
/// Use `AppException` to define known error codes in a central
/// location so that error-handling logic can match exceptions by code
/// rather than by descriptor string:
///
/// ```swift
/// extension AppException {
///     static let timedOut = AppException("801F")
///     static let unauthorized = AppException("C31B")
/// }
///
/// if exception.isEqual(to: .timedOut) {
///     retryRequest()
/// }
/// ```
///
/// - SeeAlso: ``Exception/isEqual(to:)``,
///   ``Exception/isEqual(toAny:)``
public struct AppException: Hashable, Sendable {
    // MARK: - Properties

    /// The error code this instance represents.
    public let errorCode: String

    // MARK: - Init

    /// Creates a catalogued exception with the given error code.
    ///
    /// - Parameter errorCode: The error code string to match against.
    public init(_ errorCode: String) {
        self.errorCode = errorCode
    }
}
