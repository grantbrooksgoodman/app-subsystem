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
/// ``Coalescer`` – one slot, one ``Coalescer/Policy``, the same
/// throwing and non-throwing overloads – with the key argument removed
/// from each call:
///
/// ```swift
/// let coalescer = SingleSlotCoalescer<Profile>()
///
/// // Non-throwing usage.
/// async let a = coalescer { await fetchProfile() }
/// async let b = coalescer { await fetchProfile() }
/// let (profileA, profileB) = await (a, b) // identical result
///
/// // Throwing usage.
/// let profile = try await coalescer { try await loadProfile() }
///
/// // Replacing: a newer query cancels the running one, and every
/// // caller still waiting receives the newer query's result.
/// let search = SingleSlotCoalescer<[Match]>(policy: .replace)
/// ```
public typealias SingleSlotCoalescer<Output> = Coalescer<SingleSlotKey, Output>

public extension Coalescer where Key == SingleSlotKey {
    // MARK: - Call as Function

    /// Submits a non-throwing operation to the single slot, resolving
    /// overlapping calls according to the coalescer's ``policy``.
    ///
    /// See the keyed `callAsFunction(_:_:)` overload for the full
    /// contract.
    ///
    /// - Parameter operation: The asynchronous work to perform.
    ///
    /// - Returns: The output of the operation the caller ultimately
    ///   awaits.
    func callAsFunction(
        _ operation: @escaping @Sendable () async -> Output
    ) async -> Output {
        await callAsFunction(
            SingleSlotKey(),
            operation
        )
    }

    /// Submits a throwing operation to the single slot, resolving
    /// overlapping calls according to the coalescer's ``policy``.
    ///
    /// See the keyed `callAsFunction(_:_:)` overload for the full
    /// contract.
    ///
    /// - Parameter operation: The asynchronous work to perform.
    ///
    /// - Returns: The output of the operation the caller ultimately
    ///   awaits.
    ///
    /// - Throws: The ``Exception`` thrown by that operation, if any.
    func callAsFunction(
        _ operation: @escaping Operation
    ) async throws(Exception) -> Output {
        try await callAsFunction(
            SingleSlotKey(),
            operation
        )
    }

    // MARK: - Submit Unless Cancelled

    /// Submits a non-throwing operation to the single slot, abandoning
    /// the wait if the calling task is cancelled.
    ///
    /// See the keyed `submitUnlessCancelled(_:_:)` overload for the
    /// full contract.
    ///
    /// - Parameter operation: The asynchronous work to perform.
    ///
    /// - Returns: The output of the operation the caller ultimately
    ///   awaits, or `nil` if the calling task was cancelled before it
    ///   settled.
    func submitUnlessCancelled(
        _ operation: @escaping @Sendable () async -> Output
    ) async -> Output? {
        await submitUnlessCancelled(
            SingleSlotKey(),
            operation
        )
    }

    /// Submits a throwing operation to the single slot, abandoning the
    /// wait if the calling task is cancelled.
    ///
    /// See the keyed `submitUnlessCancelled(_:_:)` overload for the
    /// full contract.
    ///
    /// - Parameter operation: The asynchronous work to perform.
    ///
    /// - Returns: The output of the operation the caller ultimately
    ///   awaits.
    ///
    /// - Throws: The ``Exception`` thrown by that operation, or a
    ///   cancellation ``Exception`` if the calling task was cancelled
    ///   before it settled.
    func submitUnlessCancelled(
        _ operation: @escaping Operation
    ) async throws(Exception) -> Output {
        try await submitUnlessCancelled(
            SingleSlotKey(),
            operation
        )
    }
}
