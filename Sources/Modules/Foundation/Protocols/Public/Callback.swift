//
//  Callback.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A result type that pairs a success value with an ``Exceptionable``
/// failure.
///
/// `Callback` is functionally similar to Swift's `Result`, but its
/// failure type is constrained to ``Exceptionable`` rather than
/// `Error`. Use it when an operation returns either a value or a
/// structured exception:
///
/// ```swift
/// func loadUser() -> Callback<User, Exception> {
///     guard let user = cache.user else {
///         return .failure(Exception(
///             "User not found.",
///             metadata: .init(sender: self)
///         ))
///     }
///     return .success(user)
/// }
/// ```
///
/// Call ``get()`` to convert the callback into a throwing expression.
///
/// - SeeAlso: ``Exception``, ``Exceptionable``
public enum Callback<Success, Failure: Exceptionable> {
    /// The operation succeeded with the associated value.
    case success(Success)

    /// The operation failed with the associated exception.
    case failure(Failure)
}

/// A type that describes a structured error with a code, descriptor,
/// reportability flag, metadata, and optional underlying exceptions.
///
/// ``Exception`` conforms to `Exceptionable`. You can also conform
/// your own error types to this protocol to participate in the
/// ``Callback`` result type.
///
/// - SeeAlso: ``Exception``, ``Callback``
public protocol Exceptionable {
    /// The deterministic error code.
    var code: String { get }

    /// A developer-facing description of the error.
    var descriptor: String { get }

    /// Whether the error can be reported.
    var isReportable: Bool { get }

    /// The source-location metadata.
    var metadata: ExceptionMetadata { get }

    /// The chain of exceptions that caused this one.
    var underlyingExceptions: [Exception]? { get }

    /// Supplementary information attached to the error.
    var userInfo: [String: Any]? { get }
}

extension Callback: @unchecked Sendable {}

public extension Callback {
    /// Creates a callback by evaluating a throwing closure.
    ///
    /// Use this as the inverse of ``get()`` to convert a
    /// `throws(Exception)` expression into a ``Callback``:
    ///
    /// ```swift
    /// let result: Callback<User, Exception> = .asCallback {
    ///     try await fetchUser()
    /// }
    /// ```
    static func asCallback(
        userInfo: [String: Any]? = nil,
        _ body: () throws -> Success
    ) -> Callback where Failure == Exception {
        do {
            return try .success(body())
        } catch let exception as Exception {
            guard let userInfo else { return .failure(exception) }
            return .failure(exception.appending(userInfo: userInfo))
        } catch {
            return .failure(Exception(
                error,
                userInfo: userInfo,
                metadata: .init(sender: self)
            ))
        }
    }

    /// Creates a callback by evaluating an asynchronous throwing
    /// closure.
    static func asCallback(
        userInfo: [String: Any]? = nil,
        _ body: () async throws -> Success
    ) async -> Callback where Failure == Exception {
        do {
            return try await .success(body())
        } catch let exception as Exception {
            guard let userInfo else { return .failure(exception) }
            return .failure(exception.appending(userInfo: userInfo))
        } catch {
            return .failure(Exception(
                error,
                userInfo: userInfo,
                metadata: .init(sender: self)
            ))
        }
    }

    /// Converts the callback to a throwing expression.
    ///
    /// Returns the success value, or throws the failure as an
    /// ``Exception``.
    func get() throws(Exception) -> Success {
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
