//
//  UncheckedSendable.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A box that asserts, without compiler verification, that its value is
/// safe to send across isolation domains.
///
/// Use `UncheckedSendable` to carry a non-`Sendable` value across a
/// concurrency boundary when you can guarantee by construction that no two
/// contexts will touch it at once – most often to capture a dependency in a
/// `@Sendable` closure, or to pass it to an `async` call that the compiler
/// would otherwise reject as a potential data race:
///
/// ```swift
/// let database = UncheckedSendable(networking.database)
/// Task.detached {
///     try await database.wrappedValue.populateTemporaryCaches()
/// }
/// ```
///
/// The box provides no synchronization. If the value is read or mutated
/// from more than one context, use ``UncheckedLockIsolated`` instead. If
/// the value is `Sendable`, no box is needed at all.
///
/// - Warning: Wrapping a value in `UncheckedSendable` silences the
///   compiler's data-race diagnostics for that value. Every use is a claim
///   you are making on the compiler's behalf, so keep the box's lifetime
///   short and the crossing it enables obvious at the call site.
@propertyWrapper
public struct UncheckedSendable<Value>: @unchecked Sendable {
    // MARK: - Properties

    public var wrappedValue: Value

    // MARK: - Init

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public init(_ wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}
