//
//  KeyedCoalescer.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A per-key async work coordinator that deduplicates concurrent
/// callers.
///
/// `KeyedCoalescer` maintains at most one in-flight task per key.
/// When multiple callers invoke the coalescer with the same key
/// while an operation is already running, they piggyback on the
/// existing task and receive the same result. Calls for different
/// keys proceed fully independently, each with their own slot.
///
/// Because `KeyedCoalescer` is an actor, all slot management is
/// concurrency-safe without external synchronization.
///
/// Both throwing and non-throwing operations are supported. Use the
/// throwing overload when the operation can fail with an
/// ``Exception``, or the non-throwing overload when it cannot:
///
/// ```swift
/// let coalescer = KeyedCoalescer<UserID, Profile>()
///
/// // Non-throwing usage.
/// async let a = coalescer(userID) { await fetchProfile(userID) }
/// async let b = coalescer(userID) { await fetchProfile(userID) }
/// let (profileA, profileB) = await (a, b) // identical result
///
/// // Throwing usage.
/// let profile = try await coalescer(userID) { try await loadProfile(userID) }
/// ```
///
/// The slot for a given key is cleared automatically when its
/// in-flight task completes – whether it succeeds or throws –
/// independent of which caller awaits it or whether callers are
/// cancelled.
///
/// - Warning: The `operation` closure is executed in an
///   unstructured `Task`. If the calling task is cancelled, the
///   coalescer's in-flight operation is *not* automatically
///   cancelled – it runs to completion so that other coalesced
///   callers still receive a result. The `callAsFunction` overloads
///   also keep *waiting* for that result regardless of cancellation;
///   use the `submitUnlessCancelled` variants to abandon the wait
///   when the calling task is cancelled. Slots accumulate one entry
///   per distinct key with an active operation; ensure the key space
///   is bounded in practice to avoid unbounded dictionary growth.
public actor KeyedCoalescer<Key: Hashable & Sendable, Output: Sendable> {
    // MARK: - Type Aliases

    /// A sendable, asynchronous closure that produces the
    /// coalescer's output value or throws an ``Exception``.
    public typealias Operation = @Sendable () async throws(Exception) -> Output

    // MARK: - Properties

    private var nonThrowingTasks: [
        Key: (id: UUID, task: Task<Output, Never>)
    ] = [:]

    private var throwingTasks: [
        Key: (id: UUID, task: Task<Output, any Error>)
    ] = [:]

    // MARK: - Init

    /// Creates a new, empty coalescer with no in-flight operations.
    public init() {}

    // MARK: - Call as Function

    /// Submits a non-throwing operation for the given key, coalescing
    /// with any in-flight task for the same key.
    ///
    /// If no operation is currently running for `key`, the coalescer
    /// starts `operation` immediately. If an operation *is* running,
    /// the caller awaits the existing task and shares its result –
    /// `operation` is never invoked.
    ///
    /// - Parameters:
    ///   - key: The value that identifies the logical work lane.
    ///     Callers with matching keys share an in-flight task;
    ///     callers with different keys run independently.
    ///   - operation: The asynchronous work to perform when no
    ///     in-flight task exists for `key`.
    ///
    /// - Returns: The output of the in-flight task for `key`,
    ///   whether it was started by this call or an earlier one.
    public func callAsFunction(
        _ key: Key,
        _ operation: @escaping @Sendable () async -> Output
    ) async -> Output {
        let task = nonThrowingTask(
            for: key,
            operation
        )

        return await task.value
    }

    /// Submits a throwing operation for the given key, coalescing
    /// with any in-flight task for the same key.
    ///
    /// If no operation is currently running for `key`, the coalescer
    /// starts `operation` immediately. If an operation *is* running,
    /// the caller awaits the existing task and shares its result –
    /// `operation` is never invoked.
    ///
    /// When the in-flight operation throws an ``Exception``, every
    /// coalesced caller receives the same error.
    ///
    /// - Parameters:
    ///   - key: The value that identifies the logical work lane.
    ///     Callers with matching keys share an in-flight task;
    ///     callers with different keys run independently.
    ///   - operation: The asynchronous work to perform when no
    ///     in-flight task exists for `key`.
    ///
    /// - Returns: The output of the in-flight task for `key`,
    ///   whether it was started by this call or an earlier one.
    ///
    /// - Throws: The ``Exception`` thrown by the in-flight operation,
    ///   if any.
    public func callAsFunction(
        _ key: Key,
        _ operation: @escaping Operation
    ) async throws(Exception) -> Output {
        let task = throwingTask(
            for: key,
            operation
        )

        return try await resolve(task)
    }

    // MARK: - Submit Unless Cancelled

    /// Submits a non-throwing operation for the given key, coalescing
    /// with any in-flight task for the same key and abandoning the
    /// wait if the calling task is cancelled.
    ///
    /// Behaves identically to the non-throwing `callAsFunction`
    /// overload while the calling task remains active. If the calling
    /// task is cancelled before the shared operation settles – or was
    /// already cancelled on entry, in which case no operation is
    /// started – `nil` is returned instead. The shared operation
    /// itself is never cancelled; other coalesced callers still
    /// receive its result, and the slot for `key` is still cleared
    /// when it completes.
    ///
    /// - Parameters:
    ///   - key: The value that identifies the logical work lane.
    ///     Callers with matching keys share an in-flight task;
    ///     callers with different keys run independently.
    ///   - operation: The asynchronous work to perform when no
    ///     in-flight task exists for `key`.
    ///
    /// - Returns: The output of the in-flight task for `key`, or
    ///   `nil` if the calling task was cancelled before it settled.
    public func submitUnlessCancelled(
        _ key: Key,
        _ operation: @escaping @Sendable () async -> Output
    ) async -> Output? {
        guard !Task.isCancelled else { return nil }

        let task = nonThrowingTask(
            for: key,
            operation
        )

        return try? await task.abandonableValue()
    }

    /// Submits a throwing operation for the given key, coalescing
    /// with any in-flight task for the same key and abandoning the
    /// wait if the calling task is cancelled.
    ///
    /// Behaves identically to the throwing `callAsFunction` overload
    /// while the calling task remains active. If the calling task is
    /// cancelled before the shared operation settles – or was already
    /// cancelled on entry, in which case no operation is started – a
    /// cancellation ``Exception`` is thrown instead. The shared
    /// operation itself is never cancelled; other coalesced callers
    /// still receive its result, and the slot for `key` is still
    /// cleared when it completes.
    ///
    /// - Parameters:
    ///   - key: The value that identifies the logical work lane.
    ///     Callers with matching keys share an in-flight task;
    ///     callers with different keys run independently.
    ///   - operation: The asynchronous work to perform when no
    ///     in-flight task exists for `key`.
    ///
    /// - Returns: The output of the in-flight task for `key`,
    ///   whether it was started by this call or an earlier one.
    ///
    /// - Throws: The ``Exception`` thrown by the in-flight operation,
    ///   or a cancellation ``Exception`` if the calling task was
    ///   cancelled before it settled.
    public func submitUnlessCancelled(
        _ key: Key,
        _ operation: @escaping Operation
    ) async throws(Exception) -> Output {
        guard !Task.isCancelled else {
            throw .cancelled(
                metadata: .init(sender: self)
            )
        }

        let task = throwingTask(
            for: key,
            operation
        )

        guard let result = try? await task.abandonableResult() else {
            throw .cancelled(
                metadata: .init(sender: self)
            )
        }

        return try resolve(result)
    }

    // MARK: - Auxiliary

    private func clearNonThrowingTaskIfMatches(
        key: Key,
        id: UUID
    ) {
        guard let existingTask = nonThrowingTasks[key],
              existingTask.id == id else { return }

        nonThrowingTasks[key] = nil
    }

    private func clearThrowingTaskIfMatches(
        key: Key,
        id: UUID
    ) {
        guard let existingTask = throwingTasks[key],
              existingTask.id == id else { return }

        throwingTasks[key] = nil
    }

    private func nonThrowingTask(
        for key: Key,
        _ operation: @escaping @Sendable () async -> Output
    ) -> Task<Output, Never> {
        if let existingTask = nonThrowingTasks[key] {
            Logger.log(
                .init(
                    "Coalescing task with existing in-flight operation.",
                    isReportable: false,
                    userInfo: [
                        "Key": key,
                        "TaskID": existingTask.id,
                    ],
                    metadata: .init(sender: self)
                ),
                domain: .concurrency
            )

            return existingTask.task
        }

        let id = UUID()
        let task = Task { await operation() }
        nonThrowingTasks[key] = (id: id, task: task)

        // Always-clear finisher; runs regardless of who awaits/cancels.
        Task { [id] in
            _ = await task.value
            self.clearNonThrowingTaskIfMatches(
                key: key,
                id: id
            )
        }

        return task
    }

    private func resolve(
        _ result: Result<Output, any Error>
    ) throws(Exception) -> Output {
        switch result {
        case let .success(output):
            return output

        case let .failure(exception as Exception):
            throw exception

        case let .failure(error):
            throw Exception(
                error,
                metadata: .init(sender: self)
            )
        }
    }

    private func resolve(
        _ task: Task<Output, any Error>
    ) async throws(Exception) -> Output {
        try await resolve(task.result)
    }

    private func throwingTask(
        for key: Key,
        _ operation: @escaping Operation
    ) -> Task<Output, any Error> {
        if let existingTask = throwingTasks[key] {
            Logger.log(
                .init(
                    "Coalescing task with existing in-flight operation.",
                    isReportable: false,
                    userInfo: [
                        "Key": key,
                        "TaskID": existingTask.id,
                    ],
                    metadata: .init(sender: self)
                ),
                domain: .concurrency
            )

            return existingTask.task
        }

        let id = UUID()
        let task = Task { try await operation() }
        throwingTasks[key] = (id: id, task: task)

        // Always-clear finisher; runs regardless of who awaits/cancels.
        Task { [id] in
            _ = await task.result
            self.clearThrowingTaskIfMatches(
                key: key,
                id: id
            )
        }

        return task
    }
}
