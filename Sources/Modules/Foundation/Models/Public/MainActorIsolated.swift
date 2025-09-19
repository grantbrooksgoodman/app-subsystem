//
//  MainActorIsolated.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
@preconcurrency import Combine
import Foundation

/// A container used to create and hold a main actor-isolated value from any isolation context. Access to the value itself must be done from the main actor.
///
/// ```swift
/// // Declaration:
/// @MainActorIsolated var service = Service.shared
///
/// // Usage off the main actor:
/// await $service.read { $0.doSomething() }
/// await $service.withValue { $0.value = newValue }
///
/// // Usage on the main actor:
/// @MainActor
/// func method() {
///     service.doSomething()
/// }
///
/// func method() {
///     Task { @MainActor in
///         service.doSomething()
///     }
/// }
/// ```
/// Access to `wrappedValue` is main actor-only; `$` helpers work from anywhere.
@dynamicMemberLookup
@propertyWrapper
public struct MainActorIsolated<Value>: @unchecked Sendable {
    // MARK: - Types

    // Box holds the actual storage and the lazy initializer.
    private final class Box: @unchecked Sendable {
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

        init(initial: @MainActor @Sendable @escaping () -> Value) {
            self.initial = initial
        }
    }

    // MARK: - Properties

    private let box: Box

    // MARK: - Init

    /// Typical use: `@MainActorIsolated var service = UIService()`.
    public init(wrappedValue: @MainActor @Sendable @autoclosure @escaping () -> Value) {
        self.box = Box(initial: wrappedValue)
    }

    // MARK: - Projected / Wrapped Value

    /// The wrapper itself (for helpers).
    public var projectedValue: MainActorIsolated<Value> { self }

    /// Main actor access to the underlying value.
    @MainActor
    public var wrappedValue: Value {
        get { box.value }
        set { box.value = newValue }
    }

    // MARK: - Subscript

    @MainActor
    public subscript<Subject>(dynamicMember keyPath: KeyPath<Value, Subject>) -> Subject {
        wrappedValue[keyPath: keyPath]
    }

    @MainActor
    public subscript<Subject>(dynamicMember keyPath: WritableKeyPath<Value, Subject>) -> Subject {
        get { wrappedValue[keyPath: keyPath] }
        set { wrappedValue[keyPath: keyPath] = newValue }
    }

    // MARK: - Nonisolated Accessors

    /// Call with a read-only closure from any context; runs on the main actor.
    public nonisolated func read<T>(
        _ body: @MainActor (Value) throws -> T
    ) async rethrows -> T {
        try await MainActor.run { try body(box.value) }
    }

    /// Call with an inout closure from any context; runs on the main actor.
    public nonisolated func withValue<T>(
        _ body: @MainActor (inout Value) throws -> T
    ) async rethrows -> T {
        try await MainActor.run {
            var value = box.value
            defer { box.value = value }
            return try body(&value)
        }
    }
}
