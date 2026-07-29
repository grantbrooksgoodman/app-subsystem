//
//  SharedStates.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// The container that holds every ``StateStream`` instance for the
/// current dependency scope.
///
/// `SharedStates` is the registry through which shared state is declared
/// and resolved. Declare each value as a computed property on a
/// `SharedStates` extension, using ``state(_:key:fileID:)``:
///
/// ```swift
/// public extension SharedStates {
///     var isLoggedIn: StateStream<Bool> { state(false) }
/// }
/// ```
///
/// Access declared state exclusively through the ``SharedState`` property
/// wrapper – `SharedStates` is intentionally not resolvable through
/// ``Dependency``:
///
/// ```swift
/// @SharedState(\.isLoggedIn) private var isLoggedIn
/// ```
///
/// Each dependency scope resolves its own container, so tests can call
/// ``DependencyValues/resetSharedValues()`` to isolate shared state:
///
/// ```swift
/// try await DependencyScopes.withDependencies {
///     $0.resetSharedValues()
/// } operation: {
///     // Shared values resolved here are isolated to this scope.
/// }
/// ```
///
/// ## Thread Safety
///
/// All stored instances are protected by ``LockIsolated``. Values can be
/// resolved from any isolation context.
///
/// - SeeAlso: ``StateStream``, ``SharedState``, ``SharedEvents``
public final class SharedStates: Sendable {
    // MARK: - Properties

    private let storage = LockIsolated([String: any Sendable]())

    // MARK: - Methods

    /// Resolves the ``StateStream`` instance for the calling declaration,
    /// creating it on first access.
    ///
    /// Call this method only from the body of the computed property that
    /// declares the value – the property's name, captured through
    /// `#function`, forms the instance's identity:
    ///
    /// ```swift
    /// public extension SharedStates {
    ///     var isLoggedIn: StateStream<Bool> { state(false) }
    /// }
    /// ```
    ///
    /// The initial value is evaluated only when the instance is first
    /// created; subsequent resolutions return the existing instance.
    ///
    /// - Warning: Calling this method from anywhere other than the computed
    ///   property that declares the value silently creates a
    ///   differently-keyed instance.
    ///
    /// - Parameters:
    ///   - initialValue: The value the state holds before the first write.
    ///   - key: The identity of the declaration. Defaults to the name of
    ///     the calling property.
    ///   - fileID: The file in which the declaration appears.
    ///
    /// - Returns: The ``StateStream`` instance for the calling declaration.
    public func state<Value: Sendable>(
        _ initialValue: @autoclosure () -> Value,
        key: String = #function,
        fileID: String = #fileID
    ) -> StateStream<Value> {
        resolve("\(fileID)#\(key)") { StateStream(initialValue()) }
    }

    // MARK: - Auxiliary

    private func resolve<T: Sendable>(
        _ key: String,
        create: () -> T
    ) -> T {
        storage.projectedValue.withValue { storage in
            if let existing = storage[key] as? T {
                return existing
            }

            let instance = create()
            storage[key] = instance

            return instance
        }
    }
}
