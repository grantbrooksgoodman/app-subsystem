//
//  BuildDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

@MainActor // swiftlint:disable:next identifier_name
var _build: Build!

/// The dependency key that provides the current ``Build`` instance.
///
/// - Important: Resolving this dependency before
///   ``AppSubsystem`` has been initialized is a fatal error.
public enum BuildDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> Build {
        guard AppSubsystem.didInitialize else { fatalError("AppSubsystem was not initialized") }
        @MainActorIsolated var build = _build!
        return build
    }
}

public extension DependencyValues {
    /// The shared ``Build`` instance.
    var build: Build {
        get { self[BuildDependency.self] }
        set { self[BuildDependency.self] = newValue }
    }
}
