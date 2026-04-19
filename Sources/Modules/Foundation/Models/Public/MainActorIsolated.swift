//
//  MainActorIsolated.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
@preconcurrency import Combine
import Foundation

/// A property wrapper that holds a main-actor-isolated value while
/// remaining `Sendable` itself.
///
/// Use `@MainActorIsolated` when you need to store a main-actor-bound
/// value – such as a UIKit service or a published object – inside a
/// type that must be `Sendable`. The wrapper defers initialization
/// until the value is first accessed on the main actor, so it is safe
/// to declare from any isolation context:
///
/// ```swift
/// @MainActorIsolated var windowService = WindowService.shared
/// ```
///
/// ## Accessing the Value
///
/// On the main actor, the wrapped value is available directly through
/// the property name and supports `@dynamicMemberLookup` for
/// key-path access:
///
/// ```swift
/// @MainActor
/// func updateTitle() {
///     windowService.title = "Home"
/// }
/// ```
///
/// From a non-main-actor context, use the projected value (`$`)
/// helpers to hop to the main actor safely:
///
/// ```swift
/// // Read-only access:
/// let title = await $windowService.read { $0.title }
///
/// // Mutating access:
/// await $windowService.withValue { $0.title = "Settings" }
/// ```
///
/// ## Lazy Initialization
///
/// The value is created lazily on first access. The initializer
/// expression is captured as an `@autoclosure` and is evaluated on
/// the main actor, so it is safe to reference main-actor-isolated
/// state in the default value.
///
/// - Note: Because ``read(_:)`` and ``withValue(_:)`` dispatch to the
///   main actor via `MainActor.run`, they are `async` and must be
///   awaited. Avoid calling them from the main actor itself, as this
///   introduces an unnecessary suspension point. On the main actor,
///   access the wrapped value directly.
///
/// - Warning: Accessing ``wrappedValue`` from outside the main actor
///   is a concurrency violation. If you are not already on the main
///   actor, use ``read(_:)`` or ``withValue(_:)`` through the
///   projected value instead.
///
/// - SeeAlso: ``LockIsolated``
@dynamicMemberLookup
@propertyWrapper
public struct MainActorIsolated<Value>: Sendable {
    // MARK: - Types

    // Box holds the actual storage and the lazy initializer.
    private final class Box: Sendable {
        /* MARK: Properties */

        private let initial: @MainActor @Sendable () -> Value

        @MainActor
        private var storage: Value?

        /* MARK: Computed Properties */

        @MainActor
        var value: Value {
            get {
                if let value = storage { return value }
                let value = initial()
                storage = value
                return value
            }
            set { storage = newValue }
        }

        /* MARK: Init */

        init(initial: @escaping @MainActor @Sendable () -> Value) {
            self.initial = initial
        }
    }

    // MARK: - Properties

    private let box: Box

    // MARK: - Init

    /// Creates a main-actor-isolated wrapper with a lazily evaluated
    /// default value.
    ///
    /// The `wrappedValue` expression is captured as an `@autoclosure`
    /// and is not evaluated until the value is first accessed on the
    /// main actor.
    ///
    /// - Parameter wrappedValue: An autoclosure that produces the
    ///   initial value. Evaluated on the main actor.
    public init(wrappedValue: @autoclosure @escaping @MainActor @Sendable () -> Value) {
        self.box = Box(initial: wrappedValue)
    }

    // MARK: - Projected / Wrapped Value

    /// The wrapper instance, accessible via the `$` prefix.
    ///
    /// Use the projected value to call ``read(_:)`` or
    /// ``withValue(_:)`` from a non-main-actor context.
    public var projectedValue: MainActorIsolated<Value> { self }

    /// The underlying value.
    ///
    /// This property is available only on the main actor. Accessing
    /// it from another isolation context is a concurrency violation.
    @MainActor
    public var wrappedValue: Value {
        get { box.value }
        set { box.value = newValue }
    }

    // MARK: - Subscript

    /// Reads a property of the underlying value by key path.
    @MainActor
    public subscript<Subject>(dynamicMember keyPath: KeyPath<Value, Subject>) -> Subject {
        wrappedValue[keyPath: keyPath]
    }

    /// Reads or writes a property of the underlying value by key
    /// path.
    @MainActor
    public subscript<Subject>(dynamicMember keyPath: WritableKeyPath<Value, Subject>) -> Subject {
        get { wrappedValue[keyPath: keyPath] }
        set { wrappedValue[keyPath: keyPath] = newValue }
    }

    // MARK: - Nonisolated Accessors

    /// Performs a read-only operation on the value from any isolation
    /// context.
    ///
    /// The closure is dispatched to the main actor via
    /// `MainActor.run`. The return value must be `Sendable` so that
    /// it can safely cross isolation boundaries.
    ///
    /// - Parameter body: A closure that receives the current value.
    ///
    /// - Returns: The value returned by `body`.
    public nonisolated func read<T: Sendable>(
        _ body: @MainActor (Value) throws -> T
    ) async rethrows -> T {
        try await MainActor.run { try body(box.value) }
    }

    /// Performs a mutating operation on the value from any isolation
    /// context.
    ///
    /// The closure is dispatched to the main actor via
    /// `MainActor.run`. Mutations made through the `inout` parameter
    /// are written back to the underlying storage when the closure
    /// returns.
    ///
    /// - Parameter body: A closure that receives the value as `inout`.
    ///
    /// - Returns: The value returned by `body`.
    public nonisolated func withValue<T: Sendable>(
        _ body: @MainActor (inout Value) throws -> T
    ) async rethrows -> T {
        try await MainActor.run {
            var value = box.value
            defer { box.value = value }
            return try body(&value)
        }
    }
}
