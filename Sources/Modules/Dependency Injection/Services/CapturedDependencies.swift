//
//  CapturedDependencies.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public struct CapturedDependencies {
    // MARK: - Properties

    let dependencies = DependencyValues.current

    // MARK: - Methods

    public func withValue<T>(_ operation: () async throws -> T) async rethrows -> T {
        try await DependencyScopes.withDependencies { dependencyValues in
            dependencyValues = dependencies
        } operation: {
            try await operation()
        }
    }

    public func withValue<T>(_ operation: () throws -> T) rethrows -> T {
        try DependencyScopes.withDependencies { dependencyValues in
            dependencyValues = dependencies
        } operation: {
            try operation()
        }
    }
}
