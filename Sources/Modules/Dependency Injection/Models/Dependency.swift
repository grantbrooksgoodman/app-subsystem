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
/// The wrapper captures the dependency scope that was active at the time
/// it was initialized. When the wrapped value is read, it merges that
/// captured scope with the scope that is current at the point of access.
/// This ensures that dependencies behave correctly even when accessed
/// inside an ``Effect`` whose closure escapes the original scope.
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

    private let initialValues: DependencyValues
    private let keyPath: KeyPath<DependencyValues, Value>

    // MARK: - Init

    /// Creates a dependency accessor for the given key path.
    ///
    /// The initializer snapshots the current ``DependencyValues`` scope
    /// so that the dependency resolves correctly regardless of when the
    /// wrapped value is later accessed.
    ///
    /// - Parameter keyPath: A key path to the desired property on
    ///   ``DependencyValues``.
    public init(_ keyPath: KeyPath<DependencyValues, Value>) {
        initialValues = DependencyValues.current
        self.keyPath = keyPath
    }

    // MARK: - Wrapped Value

    /// The resolved dependency value.
    ///
    /// Each access merges the scope captured at initialization with the
    /// scope that is current at the point of access, then reads the
    /// value at the stored key path.
    public var wrappedValue: Value {
        initialValues.merging(DependencyValues.current)[keyPath: keyPath]
    }
}
