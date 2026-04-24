//
//  SingleSlotCoalescer.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A single-lane async work coordinator that serializes or
/// replaces concurrent operations.
///
/// `SingleSlotCoalescer` maintains at most one in-flight task at a
/// time. When multiple callers request an operation concurrently, the
/// coalescer's ``Mode`` determines how the overlap is resolved:
///
/// - ``Mode/coalesce``: Subsequent callers piggyback on the
///   already-running task and receive the same result.
/// - ``Mode/lastCallerWins``: The in-flight task is cancelled and a
///   new one is started for the most recent caller. All previous
///   callers await the replacement task.
///
/// Because `SingleSlotCoalescer` is an actor, all slot management is
/// concurrency-safe without external synchronization.
///
/// ```swift
/// let coalescer = SingleSlotCoalescer<Profile>()
///
/// // Both calls share the same network request.
/// async let a = coalescer(mode: .coalesce) { await fetchProfile() }
/// async let b = coalescer(mode: .coalesce) { await fetchProfile() }
/// let (profileA, profileB) = await (a, b) // identical result
/// ```
///
/// The slot is cleared automatically when the in-flight task
/// completes, independent of which caller awaits it or whether
/// callers are cancelled.
///
/// - Important: ``Mode/lastCallerWins`` relies on *cooperative
///   cancellation*. The cancelled operation must periodically check
///   `Task.isCancelled` or call cancellation-aware APIs (such as
///   `URLSession` data methods) to stop promptly. An operation that
///   ignores cancellation will continue running in the background,
///   potentially producing stale results or unwanted side effects
///   after the replacement task has already completed.
///
/// - Warning: The `operation` closure is executed in an unstructured
///   `Task`. If the calling task is cancelled, the coalescer's
///   in-flight operation is *not* automatically cancelled – it
///   runs to completion so that other coalesced callers still
///   receive a result. Design operations to be idempotent where
///   possible, because multiple callers may trigger new operations
///   in quick succession under ``Mode/lastCallerWins``.
public actor SingleSlotCoalescer<Output: Sendable> {
    // MARK: - Type Aliases

    /// A sendable, asynchronous closure that produces the
    /// coalescer's output value.
    public typealias Operation = @Sendable () async -> Output

    // MARK: - Types

    /// The strategy used to resolve concurrent calls to the
    /// coalescer.
    ///
    /// Choose a mode based on whether callers benefit from sharing
    /// a result or whether only the most recent request matters.
    public enum Mode: Sendable {
        /// Subsequent callers share the in-flight task's result.
        ///
        /// Use this mode when every caller needs the same data and
        /// redundant work should be avoided – for example,
        /// deduplicating identical network requests.
        case coalesce

        /// The in-flight task is cancelled and replaced by a new
        /// one.
        ///
        /// Use this mode when only the most recent input is
        /// meaningful – for example, a search-as-you-type field
        /// where earlier queries are no longer relevant.
        case lastCallerWins
    }

    // MARK: - Properties

    private var currentTask: (id: UUID, task: Task<Output, Never>)?

    // MARK: - Init

    /// Creates a new, empty coalescer with no in-flight operation.
    public init() {}

    // MARK: - Call as Function

    /// Submits an operation to the coalescer, resolving overlapping
    /// calls according to the specified mode.
    ///
    /// If no operation is currently in flight, `operation` is
    /// started immediately. Otherwise, the coalescer applies the
    /// given ``Mode``:
    ///
    /// | Mode | Behavior |
    /// |---|---|
    /// | ``Mode/coalesce`` | Await the existing task. |
    /// | ``Mode/lastCallerWins`` | Cancel the existing task and start `operation`. |
    ///
    /// - Parameters:
    ///   - mode: The resolution strategy for concurrent calls. The
    ///     default is ``Mode/coalesce``.
    ///   - operation: The asynchronous work to perform.
    ///
    /// - Returns: The output of whichever task the caller ultimately
    ///   awaits.
    public func callAsFunction(
        mode: Mode = .coalesce,
        _ operation: @escaping Operation
    ) async -> Output {
        switch mode {
        case .coalesce: await coalesce(operation)
        case .lastCallerWins: await lastCallerWins(operation)
        }
    }

    // MARK: - Core Behavior

    private func coalesce(_ operation: @escaping Operation) async -> Output {
        if let currentTask {
            Logger.log(
                .init(
                    "Coalescing task with existing in-flight operation.",
                    isReportable: false,
                    userInfo: ["TaskID": currentTask.id],
                    metadata: .init(sender: self)
                ),
                domain: .concurrency
            )

            return await currentTask.task.value
        }

        return await run(operation)
    }

    private func lastCallerWins(_ operation: @escaping Operation) async -> Output {
        if let currentTask {
            Logger.log(
                .init(
                    "Cancelling previous in-flight operation to prioritize last caller.",
                    isReportable: false,
                    userInfo: ["TaskID": currentTask.id],
                    metadata: .init(sender: self)
                ),
                domain: .concurrency
            )

            currentTask.task.cancel()
        }

        return await run(operation)
    }

    // MARK: - Auxiliary

    private func clearIfMatches(id: UUID) {
        guard let currentTask,
              currentTask.id == id else { return }

        self.currentTask = nil
    }

    private func run(_ operation: @escaping Operation) async -> Output {
        let id = UUID()
        let task = Task { await operation() }
        currentTask = (id: id, task: task)

        // Always-clear finisher; runs regardless of who awaits/cancels.
        Task { [id] in
            _ = await task.value
            self.clearIfMatches(id: id)
        }

        return await task.value
    }
}
