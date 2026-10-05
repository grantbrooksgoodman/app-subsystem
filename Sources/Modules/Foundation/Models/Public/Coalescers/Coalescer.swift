//
//  Coalescer.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A per-key async work coordinator that deduplicates or replaces
/// concurrent operations.
///
/// `Coalescer` maintains at most one in-flight operation per key. When
/// a caller submits an operation for a key that already has one in
/// flight, the coalescer's ``Policy`` decides how the overlap resolves:
///
/// - ``Policy/coalesce``: The caller joins the in-flight operation and
///   receives its result. The submitted operation is never invoked.
/// - ``Policy/replace``: The in-flight operation is cancelled and the
///   submitted operation starts in its place. Every caller already
///   waiting on that key – the one that started the cancelled operation
///   and any that joined it – receives the replacement's result.
/// - ``Policy/rerun``: The in-flight operation finishes undisturbed,
///   then the submitted operation runs once more. Callers that arrive
///   during a run collapse into one rerun and receive its result.
///
/// Calls for different keys proceed independently. The policy is fixed
/// when the coalescer is created, so an instance behaves the same way
/// regardless of which caller reaches it.
///
/// Because `Coalescer` is an actor, all slot management is
/// concurrency-safe without external synchronization.
///
/// The error an operation can throw is fixed per coalescer by the
/// `Failure` type parameter, typically ``Exception``. Every caller
/// waiting on a key receives the same settlement, so a joined
/// caller only ever receives an error its own signature can throw.
/// Use `Never` for work that cannot fail: such a coalescer's calls
/// need no `try`, and a joined operation always has a value to
/// deliver.
///
/// ```swift
/// // Throwing: callers share the result or the error.
/// let profiles = Coalescer<UserID, Profile, Exception>()
/// let profile = try await profiles(userID) { try await loadProfile(userID) }
///
/// // Non-throwing: the operation cannot fail, so neither can the call.
/// let counts = Coalescer<UserID, Int, Never>()
/// async let a = counts(userID) { await countMessages(userID) }
/// async let b = counts(userID) { await countMessages(userID) }
/// let (countA, countB) = await (a, b) // identical result
/// ```
///
/// A caller is attached to the lane for its key in the same synchronous
/// step that installs or updates that lane, so no operation can settle,
/// be replaced, or be rerun between the two. The slot for a key is
/// cleared by the operation itself, as its final step, in the same
/// actor turn that delivers the result to every waiting caller. A
/// finished operation is therefore never left in place for a later
/// caller to join; a caller either joins work that is still running or
/// starts new work.
///
/// - Important: ``Policy/replace`` relies on *cooperative
///   cancellation*. The cancelled operation must periodically check
///   `Task.isCancelled` or call cancellation-aware APIs (such as
///   `URLSession` data methods) to stop promptly. An operation that
///   ignores cancellation continues running in the background; its
///   result is discarded when it finishes, but any side effects it
///   produces in the meantime are not undone.
///
/// - Warning: The `operation` closure is executed in an unstructured
///   task. If the calling task is cancelled, the coalescer's in-flight
///   operation is *not* automatically cancelled – it runs to completion
///   so that other coalesced callers still receive a result. The
///   `callAsFunction` overloads also keep *waiting* for that result
///   regardless of cancellation; use the `submitUnlessCancelled`
///   variants to abandon the wait when the calling task is cancelled.
///   Slots exist only while an operation is in flight, so memory is
///   bounded by the number of distinct keys with concurrent work.
public actor Coalescer<Key: Hashable & Sendable, Output: Sendable, Failure: Error> {
    // MARK: - Type Aliases

    /// A sendable, asynchronous closure that produces the
    /// coalescer's output value or throws its `Failure`.
    public typealias Operation = @Sendable () async throws(Failure) -> Output

    private typealias Settlement = Result<Output, Failure>
    private typealias Waiter = CheckedContinuation<Settlement?, Never>

    // MARK: - Types

    /// The strategy used to resolve a call whose key already has an
    /// operation in flight.
    ///
    /// Choose a policy based on whether callers benefit from sharing
    /// a result or whether only the most recent request matters.
    public enum Policy: Sendable {
        /// Subsequent callers share the in-flight operation's result.
        ///
        /// Use this policy when every caller needs the same data and
        /// redundant work should be avoided – for example,
        /// deduplicating identical network requests.
        case coalesce

        /// The in-flight operation is cancelled and replaced by the
        /// caller's, and every waiting caller receives the
        /// replacement's result.
        ///
        /// Use this policy when only the most recent input is
        /// meaningful – for example, a search-as-you-type field
        /// where earlier queries are no longer relevant.
        case replace

        /// The caller waits for the in-flight operation to finish, and
        /// then for the operation to run once more.
        ///
        /// Calls that arrive during a run collapse into a single rerun,
        /// which uses the most recent caller's operation. Every caller
        /// that arrived during the run receives the rerun's result,
        /// while the callers that started or joined the run receive its
        /// own. The rerun happens whether the run succeeded or failed,
        /// and whether or not anyone is still waiting for it. Calls
        /// that arrive during the rerun schedule one further rerun, so
        /// at most one is ever pending.
        ///
        /// Use this policy when a request signals that state has
        /// changed since the in-flight work began – a server push
        /// observed mid-refresh, for example – so the work must
        /// complete at least once after every request without
        /// discarding work in progress.
        case rerun
    }

    private struct Lane {
        let id: UUID
        let task: Task<Void, Never>

        /// The operation to run once the current one finishes, when a
        /// ``Policy/rerun`` caller arrived during it.
        var pendingOperation: Operation?

        /// The callers waiting on the rerun rather than the current run.
        var pendingWaiters = [UUID: Waiter]()

        var waiters: [UUID: Waiter]
    }

    // MARK: - Properties

    /// The strategy this coalescer applies to overlapping calls.
    public let policy: Policy

    private var lanes = [Key: Lane]()

    // MARK: - Init

    /// Creates a new, empty coalescer with no in-flight operations.
    ///
    /// - Parameter policy: The strategy to apply to overlapping calls.
    ///   The default is ``Policy/coalesce``.
    public init(
        policy: Policy = .coalesce
    ) {
        self.policy = policy
    }

    // MARK: - Call as Function

    /// Submits an operation for the given key, resolving overlapping
    /// calls according to the coalescer's ``policy``.
    ///
    /// If no operation is currently running for `key`, the coalescer
    /// starts `operation` immediately. If an operation *is* running,
    /// the ``policy`` decides whether the caller joins it, replaces
    /// it, or waits for it and a rerun; under ``Policy/coalesce`` the
    /// submitted operation is never invoked.
    ///
    /// When the operation the caller ultimately awaits throws, every
    /// caller waiting on it receives the same error.
    ///
    /// - Parameters:
    ///   - key: The value that identifies the logical work lane.
    ///     Callers with matching keys share or replace one another's
    ///     work; callers with different keys run independently.
    ///   - operation: The asynchronous work to perform.
    ///
    /// - Returns: The output of the operation the caller ultimately
    ///   awaits.
    ///
    /// - Throws: The `Failure` thrown by that operation, if any.
    public func callAsFunction(
        _ key: Key,
        _ operation: @escaping Operation
    ) async throws(Failure) -> Output {
        try await settle(
            key,
            operation
        ).get()
    }

    // MARK: - Submit Unless Cancelled

    /// Submits an operation for the given key, resolving overlapping
    /// calls according to the coalescer's ``policy`` and abandoning
    /// the wait if the calling task is cancelled.
    ///
    /// Behaves identically to `callAsFunction(_:_:)` while the calling
    /// task remains active. If the calling task is cancelled before
    /// the operation settles – or was already cancelled on entry, in
    /// which case no operation is started – `nil` is returned instead.
    /// The operation itself is never cancelled by this method; other
    /// waiting callers still receive its result, and the slot for
    /// `key` is still cleared when it completes.
    ///
    /// - Parameters:
    ///   - key: The value that identifies the logical work lane.
    ///     Callers with matching keys share or replace one another's
    ///     work; callers with different keys run independently.
    ///   - operation: The asynchronous work to perform.
    ///
    /// - Returns: The output of the operation the caller ultimately
    ///   awaits, or `nil` if the calling task was cancelled before it
    ///   settled.
    ///
    /// - Throws: The `Failure` thrown by that operation, if it settles
    ///   before the calling task is cancelled.
    public func submitUnlessCancelled(
        _ key: Key,
        _ operation: @escaping Operation
    ) async throws(Failure) -> Output? {
        guard !Task.isCancelled,
              let settlement = await wait(
                  on: key,
                  operation,
                  abandonable: true
              ) else { return nil }

        return try settlement.get()
    }

    // MARK: - Auxiliary

    /// Removes a waiter whose task was cancelled and resumes it with
    /// `nil`. No-op if the waiter already settled.
    private func abandon(
        _ key: Key,
        waiterID: UUID
    ) {
        guard var lane = lanes[key] else { return }

        var waiter = lane.waiters.removeValue(forKey: waiterID)
        if waiter == nil {
            waiter = lane.pendingWaiters.removeValue(forKey: waiterID)
        }

        guard let waiter else { return }

        lanes[key] = lane
        waiter.resume(returning: nil)
    }

    /// Delivers an operation's result to every caller waiting on its
    /// lane, then either clears the slot or, if a rerun was requested
    /// during the run, starts it with the rerun's waiters attached –
    /// all in one actor turn.
    ///
    /// A result from an operation that has since been replaced is
    /// discarded; its waiters were carried over to the replacement
    /// and will be settled by it.
    private func complete(
        _ key: Key,
        laneID: UUID,
        with settlement: Settlement
    ) {
        guard let lane = lanes[key],
              lane.id == laneID else { return }

        if let pendingOperation = lane.pendingOperation {
            Logger.log(
                .init(
                    "Rerunning operation for callers that arrived during the previous run.",
                    isReportable: false,
                    userInfo: [
                        "Key": key,
                        "TaskID": lane.id,
                    ],
                    metadata: .init(sender: self)
                ),
                domain: .concurrency
            )

            let rerun = start(
                key,
                pendingOperation
            )

            lanes[key] = Lane(
                id: rerun.id,
                task: rerun.task,
                waiters: lane.pendingWaiters
            )
        } else {
            lanes[key] = nil
        }

        for waiter in lane.waiters.values {
            waiter.resume(returning: settlement)
        }
    }

    /// Attaches `waiter` to the lane for `key`, joining, replacing, or
    /// scheduling a rerun of the work in flight according to
    /// ``policy``, or starting `operation` when nothing is in flight.
    ///
    /// This runs synchronously inside the continuation closure of
    /// `wait(on:_:abandonable:)`, so the lane and the waiter attached
    /// to it are written in one step. There is no point between the
    /// two at which an operation could settle, be replaced, or be
    /// rerun, and therefore no lane a waiter can miss.
    private func enlist(
        _ waiter: Waiter,
        as waiterID: UUID,
        on key: Key,
        _ operation: @escaping Operation
    ) {
        guard var lane = lanes[key] else {
            let started = start(
                key,
                operation
            )

            lanes[key] = Lane(
                id: started.id,
                task: started.task,
                waiters: [waiterID: waiter]
            )

            return
        }

        switch policy {
        case .coalesce:
            Logger.log(
                .init(
                    "Coalescing task with existing in-flight operation.",
                    isReportable: false,
                    userInfo: [
                        "Key": key,
                        "TaskID": lane.id,
                    ],
                    metadata: .init(sender: self)
                ),
                domain: .concurrency
            )

            lane.waiters[waiterID] = waiter

        case .replace:
            Logger.log(
                .init(
                    "Cancelling previous in-flight operation to prioritize last caller.",
                    isReportable: false,
                    userInfo: [
                        "Key": key,
                        "TaskID": lane.id,
                    ],
                    metadata: .init(sender: self)
                ),
                domain: .concurrency
            )

            lane.task.cancel()

            // The displaced operation's waiters move to the
            // replacement, so they receive its result rather than
            // whatever the cancelled operation returns.
            let replacement = start(
                key,
                operation
            )

            lane = Lane(
                id: replacement.id,
                task: replacement.task,
                waiters: lane.waiters
            )

            lane.waiters[waiterID] = waiter

        case .rerun:
            Logger.log(
                .init(
                    "Scheduling rerun of in-flight operation for last caller.",
                    isReportable: false,
                    userInfo: [
                        "Key": key,
                        "TaskID": lane.id,
                    ],
                    metadata: .init(sender: self)
                ),
                domain: .concurrency
            )

            // The most recent caller's operation is the one that
            // reruns, and its waiters attach to the rerun rather
            // than to the run in progress.
            lane.pendingOperation = operation
            lane.pendingWaiters[waiterID] = waiter
        }

        lanes[key] = lane
    }

    /// Joins or starts the lane for `key` according to ``policy``,
    /// then waits for it to settle without abandoning the wait.
    private func settle(
        _ key: Key,
        _ operation: @escaping Operation
    ) async -> Settlement {
        guard let settlement = await wait(
            on: key,
            operation,
            abandonable: false
        ) else {
            // Only `abandon` resumes a waiter with `nil`, and only a
            // cancellation handler calls it – which a wait that cannot
            // be abandoned never installs.
            fatalError(
                "A wait that cannot be abandoned always settles."
            )
        }

        return settlement
    }

    /// Runs `operation` in its own task and, as that task's final
    /// step, delivers the result to the lane for `key`.
    private func start(
        _ key: Key,
        _ operation: @escaping Operation
    ) -> (id: UUID, task: Task<Void, Never>) {
        let id = UUID()
        let task = Task.detached(priority: Task.currentPriority) {
            let settlement: Settlement
            do throws(Failure) {
                settlement = try await .success(operation())
            } catch {
                settlement = .failure(error)
            }

            await self.complete(
                key,
                laneID: id,
                with: settlement
            )
        }

        return (id, task)
    }

    /// Enlists in the lane for `key` and suspends until it settles.
    ///
    /// Enlisting happens inside the continuation closure, which runs
    /// synchronously before the caller suspends, so the lane this
    /// waiter joins or starts cannot settle or be replaced before the
    /// waiter is attached to it.
    ///
    /// - Returns: The lane's settlement, or `nil` if `abandonable` is
    ///   `true` and the calling task was cancelled first.
    private func wait(
        on key: Key,
        _ operation: @escaping Operation,
        abandonable: Bool
    ) async -> Settlement? {
        let waiterID = UUID()

        guard abandonable else {
            return await withCheckedContinuation { continuation in
                enlist(
                    continuation,
                    as: waiterID,
                    on: key,
                    operation
                )
            }
        }

        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                enlist(
                    continuation,
                    as: waiterID,
                    on: key,
                    operation
                )
            }
        } onCancel: {
            Task {
                await self.abandon(
                    key,
                    waiterID: waiterID
                )
            }
        }
    }
}
