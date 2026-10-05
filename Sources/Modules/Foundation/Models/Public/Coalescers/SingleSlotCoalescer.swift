//
//  SingleSlotCoalescer.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// The key of a ``SingleSlotCoalescer``.
///
/// A single-slot coalescer has exactly one lane, so its key carries no
/// information. The type exists only to specialize ``Coalescer``;
/// callers never pass it.
public struct SingleSlotKey: Hashable, Sendable {
    public init() {}
}

/// A ``Coalescer`` with a single lane.
///
/// Use a single-slot coalescer when every caller requests the same
/// work and there is nothing to key on. It is the same actor as
/// ``Coalescer`` – one slot, one ``Coalescer/Policy``, one
/// `Failure` – with the key argument removed from each call:
///
/// ```swift
/// // Throwing: callers share the result or the error.
/// let profile = SingleSlotCoalescer<Profile, Exception>()
/// let current = try await profile { try await loadProfile() }
///
/// // Non-throwing: the operation cannot fail, so neither can the call.
/// let count = SingleSlotCoalescer<Int, Never>()
/// async let a = count { await countMessages() }
/// async let b = count { await countMessages() }
/// let (countA, countB) = await (a, b) // identical result
///
/// // Replacing: a newer query cancels the running one, and every
/// // caller still waiting receives the newer query's result.
/// let search = SingleSlotCoalescer<[Match], Exception>(policy: .replace)
/// ```
public typealias SingleSlotCoalescer<Output: Sendable, Failure: Error> = Coalescer<SingleSlotKey, Output, Failure>

public extension Coalescer where Key == SingleSlotKey {
    // MARK: - Call as Function

    /// Submits an operation to the single slot, resolving overlapping
    /// calls according to the coalescer's ``policy``.
    ///
    /// See the keyed `callAsFunction(_:_:)` overload for the full
    /// contract.
    ///
    /// - Parameter operation: The asynchronous work to perform.
    ///
    /// - Returns: The output of the operation the caller ultimately
    ///   awaits.
    ///
    /// - Throws: The `Failure` thrown by that operation, if any.
    func callAsFunction(
        _ operation: @escaping Operation
    ) async throws(Failure) -> Output {
        try await callAsFunction(
            SingleSlotKey(),
            operation
        )
    }

    // MARK: - Submit Unless Cancelled

    /// Submits an operation to the single slot, abandoning the wait if
    /// the calling task is cancelled.
    ///
    /// See the keyed `submitUnlessCancelled(_:_:)` overload for the
    /// full contract.
    ///
    /// - Parameter operation: The asynchronous work to perform.
    ///
    /// - Returns: The output of the operation the caller ultimately
    ///   awaits, or `nil` if the calling task was cancelled before it
    ///   settled.
    ///
    /// - Throws: The `Failure` thrown by that operation, if it settles
    ///   before the calling task is cancelled.
    func submitUnlessCancelled(
        _ operation: @escaping Operation
    ) async throws(Failure) -> Output? {
        try await submitUnlessCancelled(
            SingleSlotKey(),
            operation
        )
    }
}
