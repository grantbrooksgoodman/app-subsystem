//
//  DependencyScopes.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public enum DependencyScopes {
    // MARK: - Methods

    public static func withDependencies<T>(
        _ modifier: (inout DependencyValues) -> Void,
        operation: () async throws -> T
    ) async rethrows -> T {
        var dependencies = DependencyValues.current
        modifier(&dependencies)
        return try await DependencyValues.$current.withValue(dependencies) {
            try await operation()
        }
    }

    public static func withDependencies<T>(
        _ modifier: (inout DependencyValues) -> Void,
        operation: () throws -> T
    ) rethrows -> T {
        var dependencies = DependencyValues.current
        modifier(&dependencies)
        return try DependencyValues.$current.withValue(dependencies) {
            try operation()
        }
    }

    public static func withEscapedDependencies<T>(_ operation: (CapturedDependencies) async throws -> T) async rethrows -> T {
        try await operation(CapturedDependencies())
    }

    public static func withEscapedDependencies<T>(_ operation: (CapturedDependencies) throws -> T) rethrows -> T {
        try operation(CapturedDependencies())
    }
}
