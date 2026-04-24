//
//  Dependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A property wrapper that reads a dependency from the current scope.
///
/// Use `@Dependency` in reducers, services, or other non-view code to
/// access a registered dependency by its key path on
/// ``DependencyValues``:
///
/// ```swift
/// @Dependency(\.urlSession) var urlSession: URLSession
/// @Dependency(\.userDefaults) var userDefaults: UserDefaults
/// ```
///
/// The wrapper resolves its value from ``DependencyValues/current``
/// each time you read ``wrappedValue``. Overrides applied by
/// ``DependencyScopes/withDependencies(_:operation:)`` are visible
/// to any `@Dependency` access within that scope.
///
/// ``Effect`` captures and restores the active scope before running
/// its closure, so dependencies resolved inside an effect see the
/// values that were active when the effect was created. To preserve
/// overrides across an escaping boundary outside of ``Effect``, use
/// ``DependencyScopes/withEscapedDependencies(_:)`` and restore
/// the captured scope at the access site.
///
/// - Important: The wrapper resolves from the scope that is active at
///   the point of access, not the scope that was active when the
///   wrapper was initialized. Because ``DependencyValues/current`` is
///   a `@TaskLocal` value, overrides are visible only for the duration
///   of the ``DependencyScopes/withDependencies(_:operation:)``
///   closure. Accessing the dependency after that closure returns
///   resolves from the enclosing scope.
///
/// For SwiftUI views that need to observe an `ObservableObject`
/// dependency for state-driven updates, use ``ObservedDependency``
/// instead.
///
/// - SeeAlso: ``DependencyKey``, ``DependencyValues``,
///   ``ObservedDependency``
@propertyWrapper
public struct Dependency<Value>: @unchecked Sendable {
    // MARK: - Properties

    private let keyPath: KeyPath<DependencyValues, Value>

    // MARK: - Init

    /// Creates a dependency accessor for the given key path.
    ///
    /// - Parameter keyPath: A key path to the desired property on
    ///   ``DependencyValues``.
    public init(_ keyPath: KeyPath<DependencyValues, Value>) {
        self.keyPath = keyPath
    }

    // MARK: - Wrapped Value

    /// The current value of the dependency.
    ///
    /// Reading this property resolves the value from the
    /// ``DependencyValues`` scope that is active at the point of
    /// access.
    public var wrappedValue: Value {
        DependencyValues.current[keyPath: keyPath]
    }
}
