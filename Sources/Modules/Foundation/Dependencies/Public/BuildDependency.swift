//
//  BuildDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

// final class BuildResolver: @unchecked Sendable {
//    static let shared = BuildResolver()
//    var build: Build?
//    private init() {}
// }

// swiftlint:disable:next identifier_name
nonisolated(unsafe) var _build: Build!

public enum BuildDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> Build {
        guard AppSubsystem.didInitialize else { fatalError("AppSubsystem was not initialized") }
        return _build
    }
}

public extension DependencyValues {
    var build: Build {
        get { self[BuildDependency.self] }
        set { self[BuildDependency.self] = newValue }
    }
}
