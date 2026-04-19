//
//  DependencyKey.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A type that provides a default value for a dependency.
///
/// Conform to `DependencyKey` to register a new dependency with the
/// dependency injection system. Each key declares the type of value it
/// provides and a method that produces the default instance:
///
/// ```swift
/// enum UserDefaultsDependency: DependencyKey {
///     static func resolve(_ dependencies: DependencyValues) -> UserDefaults {
///         .standard
///     }
/// }
/// ```
///
/// After defining a key, expose it on ``DependencyValues`` through a
/// computed property so that callers can access it by key path:
///
/// ```swift
/// extension DependencyValues {
///     var userDefaults: UserDefaults {
///         get { self[UserDefaultsDependency.self] }
///         set { self[UserDefaultsDependency.self] = newValue }
///     }
/// }
/// ```
///
/// The ``resolve(_:)`` method receives the current ``DependencyValues``
/// container, which allows a dependency to compose other dependencies
/// during resolution.
///
/// - SeeAlso: ``DependencyValues``, ``Dependency``
public protocol DependencyKey {
    // MARK: - Associated Types

    /// The type of value this key provides.
    associatedtype Value

    // MARK: - Methods

    /// Returns the default value for this dependency.
    ///
    /// The system calls this method the first time the dependency is
    /// accessed and caches the result for subsequent lookups within the
    /// same scope.
    ///
    /// - Parameter dependencies: The current dependency container,
    ///   available for composing other dependencies during resolution.
    ///
    /// - Returns: The resolved dependency value.
    static func resolve(_ dependencies: DependencyValues) -> Value
}
