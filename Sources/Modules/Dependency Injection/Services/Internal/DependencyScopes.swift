//
//  DependencyScopes.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A namespace for functions that override or capture dependencies for
/// the duration of a closure.
///
/// Use `DependencyScopes` to control which dependency values are visible
/// to a block of work.
///
/// ## Overriding Dependencies
///
/// Call ``withDependencies(_:operation:)`` to replace one or more
/// dependencies for the duration of an operation. This is especially
/// useful in tests, where you can substitute a mock without changing
/// production code:
///
/// ```swift
/// let items = try await DependencyScopes.withDependencies {
///     $0.urlSession = mockSession
/// } operation: {
///     try await service.fetchItems()
/// }
/// ```
///
/// ## Escaping Closures
///
/// Swift's `@TaskLocal` values do not propagate into escaping closures.
/// When you need to preserve the current scope across an escaping
/// boundary – such as an ``Effect`` – use
/// ``withEscapedDependencies(_:)``. The closure receives a
/// ``CapturedDependencies`` value that can restore the scope later:
///
/// ```swift
/// DependencyScopes.withEscapedDependencies { captured in
///     Effect.run { send in
///         await captured.withValue {
///             // Dependencies are available here.
///         }
///     }
/// }
/// ```
///
/// - SeeAlso: ``DependencyValues``, ``CapturedDependencies``
enum DependencyScopes {
    // MARK: - Methods

    /// Overrides dependencies for the duration of an asynchronous
    /// operation.
    ///
    /// The `modifier` closure receives the current ``DependencyValues``
    /// as an `inout` parameter. Any changes you make are visible to
    /// code executed inside `operation`, but do not affect the
    /// surrounding scope.
    ///
    /// - Parameters:
    ///   - modifier: A closure that mutates the current dependency
    ///     values.
    ///   - operation: The asynchronous work to perform with the modified
    ///     dependencies.
    ///
    /// - Returns: The value returned by `operation`.
    static func withDependencies<T>(
        _ modifier: (inout DependencyValues) -> Void,
        operation: () async throws -> T
    ) async rethrows -> T {
        var dependencies = DependencyValues.current
        modifier(&dependencies)
        return try await DependencyValues.$current.withValue(dependencies) {
            try await operation()
        }
    }

    /// Overrides dependencies for the duration of a synchronous
    /// operation.
    ///
    /// - Parameters:
    ///   - modifier: A closure that mutates the current dependency
    ///     values.
    ///   - operation: The synchronous work to perform with the modified
    ///     dependencies.
    ///
    /// - Returns: The value returned by `operation`.
    static func withDependencies<T>(
        _ modifier: (inout DependencyValues) -> Void,
        operation: () throws -> T
    ) rethrows -> T {
        var dependencies = DependencyValues.current
        modifier(&dependencies)
        return try DependencyValues.$current.withValue(dependencies) {
            try operation()
        }
    }

    /// Captures the current dependency scope for use in escaping
    /// closures.
    ///
    /// - Parameter operation: A closure that receives the captured
    ///   dependencies.
    ///
    /// - Returns: The value returned by `operation`.
    static func withEscapedDependencies<T>(
        _ operation: (CapturedDependencies) throws -> T
    ) rethrows -> T {
        try operation(CapturedDependencies())
    }
}
