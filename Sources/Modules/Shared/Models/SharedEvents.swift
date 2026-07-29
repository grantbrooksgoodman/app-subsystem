//
//  SharedEvents.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// The container that holds every ``EventStream`` instance for the
/// current dependency scope.
///
/// `SharedEvents` is the registry through which shared events are
/// declared and resolved. Declare each event as a computed property on a
/// `SharedEvents` extension, using ``event(key:fileID:)``:
///
/// ```swift
/// public extension SharedEvents {
///     var sessionDidExpire: EventStream<Void> { event() }
/// }
/// ```
///
/// Access declared events exclusively through the ``SharedEvent``
/// property wrapper – `SharedEvents` is intentionally not resolvable
/// through ``Dependency``:
///
/// ```swift
/// @SharedEvent(\.sessionDidExpire) private var sessionDidExpire
/// ```
///
/// Each dependency scope resolves its own container, so tests can call
/// ``DependencyValues/resetSharedValues()`` to isolate shared events:
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
/// All stored instances are protected by ``LockIsolated``. Events can be
/// resolved from any isolation context.
///
/// - SeeAlso: ``EventStream``, ``SharedStates``
public final class SharedEvents: Sendable {
    // MARK: - Properties

    private let storage = LockIsolated([String: any Sendable]())

    // MARK: - Methods

    /// Resolves the ``EventStream`` instance for the calling declaration,
    /// creating it on first access.
    ///
    /// Call this method only from the body of the computed property that
    /// declares the event – the property's name, captured through
    /// `#function`, forms the instance's identity:
    ///
    /// ```swift
    /// public extension SharedEvents {
    ///     var sessionDidExpire: EventStream<Void> { event() }
    /// }
    /// ```
    ///
    /// - Warning: Calling this method from anywhere other than the computed
    ///   property that declares the event silently creates a
    ///   differently-keyed instance.
    ///
    /// - Parameters:
    ///   - key: The identity of the declaration. Defaults to the name of
    ///     the calling property.
    ///   - fileID: The file in which the declaration appears.
    ///
    /// - Returns: The ``EventStream`` instance for the calling declaration.
    public func event<Payload: Sendable>(
        key: String = #function,
        fileID: String = #fileID
    ) -> EventStream<Payload> {
        resolve("\(fileID)#\(key)") { EventStream() }
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
