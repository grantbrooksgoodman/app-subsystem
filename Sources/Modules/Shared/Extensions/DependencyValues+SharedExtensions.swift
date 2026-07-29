//
//  DependencyValues+SharedExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension DependencyValues {
    /// Replaces the shared state and event containers for the current
    /// scope with fresh, empty instances.
    ///
    /// Call this method in tests to isolate shared values, so that reads,
    /// writes, and subscriptions within the scope cannot leak into other
    /// tests:
    ///
    /// ```swift
    /// try await DependencyScopes.withDependencies {
    ///     $0.resetSharedValues()
    /// } operation: {
    ///     // Shared values resolved here are isolated to this scope.
    /// }
    /// ```
    mutating func resetSharedValues() {
        self[SharedEventsDependency.self] = .init()
        self[SharedStatesDependency.self] = .init()
    }
}
