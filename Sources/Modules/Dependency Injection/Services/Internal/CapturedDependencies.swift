//
//  CapturedDependencies.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A snapshot of dependency values that can be restored in an escaping
/// closure.
///
/// Because Swift's `@TaskLocal` storage does not propagate into escaping
/// closures, any ``Dependency`` accessed inside an escaping context
/// would otherwise see only the default values. `CapturedDependencies`
/// solves this by freezing the current ``DependencyValues`` at the
/// point of capture and restoring them on demand.
///
/// You obtain a `CapturedDependencies` value from
/// ``DependencyScopes/withEscapedDependencies(_:)``:
///
/// ```swift
/// DependencyScopes.withEscapedDependencies { captured in
///     Effect.run { send in
///         await captured.withValue {
///             // The dependency scope from the call site is
///             // available here, even though this closure escapes.
///         }
///     }
/// }
/// ```
///
/// - SeeAlso: ``DependencyScopes``, ``DependencyValues``
struct CapturedDependencies: Sendable {
    // MARK: - Properties

    let dependencies = DependencyValues.current

    // MARK: - Methods

    /// Restores the captured dependency scope for the duration of an
    /// asynchronous operation.
    ///
    /// - Parameter operation: The work to perform with the restored
    ///   dependencies.
    ///
    /// - Returns: The value returned by `operation`.
    func withValue<T>(
        _ operation: () async throws -> T
    ) async rethrows -> T {
        try await DependencyScopes.withDependencies { dependencyValues in
            dependencyValues = dependencies
        } operation: {
            try await operation()
        }
    }

    /// Restores the captured dependency scope for the duration of a
    /// synchronous operation.
    ///
    /// - Parameter operation: The work to perform with the restored
    ///   dependencies.
    ///
    /// - Returns: The value returned by `operation`.
    func withValue<T>(
        _ operation: () throws -> T
    ) rethrows -> T {
        try DependencyScopes.withDependencies { dependencyValues in
            dependencyValues = dependencies
        } operation: {
            try operation()
        }
    }
}
