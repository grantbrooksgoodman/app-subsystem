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
/// Both throwing and non-throwing operations are supported, and they
/// share the same slot for a given key. Use the throwing overload when
/// the operation can fail with an ``Exception``, or the non-throwing
/// overload when it cannot:
///
/// ```swift
/// let coalescer = Coalescer<UserID, Profile>()
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
/// The slot for a key is cleared by the operation itself, as its final
/// step, in the same actor turn that delivers the result to every
/// waiting caller. A finished operation is therefore never left in
/// place for a later caller to join; a caller either joins work that
/// is still running or starts new work.
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
public actor Coalescer<Key: Hashable & Sendable, Output: Sendable> {
    // MARK: - Type Aliases

    /// A sendable, asynchronous closure that produces the
    /// coalescer's output value or throws an ``Exception``.
    public typealias Operation = @Sendable () async throws(Exception) -> Output

    private typealias Settlement = Result<Output, Exception>
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

    /// Submits a non-throwing operation for the given key, resolving
    /// overlapping calls according to the coalescer's ``policy``.
    ///
    /// If no operation is currently running for `key`, the coalescer
    /// starts `operation` immediately. If an operation *is* running,
    /// the ``policy`` decides whether the caller joins it or replaces
    /// it; under ``Policy/coalesce`` the submitted operation is never
    /// invoked.
    ///
    /// If the operation this call joins was started by a throwing
    /// caller and fails, this call has no shared value to return. It
    /// then runs its own `operation` directly and returns that result.
    ///
    /// - Parameters:
    ///   - key: The value that identifies the logical work lane.
    ///     Callers with matching keys share or replace one another's
    ///     work; callers with different keys run independently.
    ///   - operation: The asynchronous work to perform.
    ///
    /// - Returns: The output of the operation the caller ultimately
    ///   awaits.
    public func callAsFunction(
        _ key: Key,
        _ operation: @escaping @Sendable () async -> Output
    ) async -> Output {
        switch await settle(
            key,
            operation,
            abandonable: false
        ) {
        case let .success(output)?:
            return output

        case let .failure(exception)?:
            Logger.log(
                exception.appending(
                    underlyingException: .init(
                        "Joined operation failed; running this caller's non-throwing operation directly.",
                        isReportable: false,
                        metadata: .init(sender: self)
                    )
                ),
                domain: .concurrency
            )

            return await operation()

        case nil:
            // Unreachable: a wait that cannot be abandoned always settles.
            return await operation()
        }
    }

    /// Submits a throwing operation for the given key, resolving
    /// overlapping calls according to the coalescer's ``policy``.
    ///
    /// If no operation is currently running for `key`, the coalescer
    /// starts `operation` immediately. If an operation *is* running,
    /// the ``policy`` decides whether the caller joins it or replaces
    /// it; under ``Policy/coalesce`` the submitted operation is never
    /// invoked.
    ///
    /// When the operation the caller ultimately awaits throws an
    /// ``Exception``, every caller waiting on it receives the same
    /// error.
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
    /// - Throws: The ``Exception`` thrown by that operation, if any.
    public func callAsFunction(
        _ key: Key,
        _ operation: @escaping Operation
    ) async throws(Exception) -> Output {
        switch await settle(
            key,
            operation,
            abandonable: false
        ) {
        case let .success(output)?:
            return output

        case let .failure(exception)?:
            throw exception

        case nil:
            // Unreachable: a wait that cannot be abandoned always settles.
            throw .cancelled(metadata: .init(sender: self))
        }
    }

    // MARK: - Submit Unless Cancelled

    /// Submits a non-throwing operation for the given key, resolving
    /// overlapping calls according to the coalescer's ``policy`` and
    /// abandoning the wait if the calling task is cancelled.
    ///
    /// Behaves identically to the non-throwing `callAsFunction`
    /// overload while the calling task remains active. If the calling
    /// task is cancelled before the operation settles – or was already
    /// cancelled on entry, in which case no operation is started –
    /// `nil` is returned instead. The operation itself is never
    /// cancelled by this method; other waiting callers still receive
    /// its result, and the slot for `key` is still cleared when it
    /// completes.
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
    public func submitUnlessCancelled(
        _ key: Key,
        _ operation: @escaping @Sendable () async -> Output
    ) async -> Output? {
        guard !Task.isCancelled else { return nil }

        switch await settle(
            key,
            operation,
            abandonable: true
        ) {
        case let .success(output)?:
            return output

        case let .failure(exception)?:
            guard !Task.isCancelled else { return nil }

            Logger.log(
                exception.appending(
                    underlyingException: .init(
                        "Joined operation failed; running this caller's non-throwing operation directly.",
                        isReportable: false,
                        metadata: .init(sender: self)
                    )
                ),
                domain: .concurrency
            )

            return await operation()

        case nil:
            return nil
        }
    }

    /// Submits a throwing operation for the given key, resolving
    /// overlapping calls according to the coalescer's ``policy`` and
    /// abandoning the wait if the calling task is cancelled.
    ///
    /// Behaves identically to the throwing `callAsFunction` overload
    /// while the calling task remains active. If the calling task is
    /// cancelled before the operation settles – or was already
    /// cancelled on entry, in which case no operation is started – a
    /// cancellation ``Exception`` is thrown instead. The operation
    /// itself is never cancelled by this method; other waiting callers
    /// still receive its result, and the slot for `key` is still
    /// cleared when it completes.
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
    /// - Throws: The ``Exception`` thrown by that operation, or a
    ///   cancellation ``Exception`` if the calling task was cancelled
    ///   before it settled.
    public func submitUnlessCancelled(
        _ key: Key,
        _ operation: @escaping Operation
    ) async throws(Exception) -> Output {
        guard !Task.isCancelled else {
            throw .cancelled(metadata: .init(sender: self))
        }

        switch await settle(
            key,
            operation,
            abandonable: true
        ) {
        case let .success(output)?:
            return output

        case let .failure(exception)?:
            throw exception

        case nil:
            throw .cancelled(metadata: .init(sender: self))
        }
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

    private func register(
        _ waiter: Waiter,
        on key: Key,
        as waiterID: UUID,
        pending: Bool
    ) {
        // The lane was installed earlier in this same actor turn, so it
        // is always present here.
        if pending {
            lanes[key]?.pendingWaiters[waiterID] = waiter
        } else {
            lanes[key]?.waiters[waiterID] = waiter
        }
    }

    /// Joins or starts the lane for `key` according to ``policy``,
    /// then waits for it to settle.
    ///
    /// - Returns: The lane's settlement, or `nil` if `abandonable` is
    ///   `true` and the calling task was cancelled first.
    private func settle(
        _ key: Key,
        _ operation: @escaping Operation,
        abandonable: Bool
    ) async -> Settlement? {
        let waiterID = UUID()
        var waitsOnRerun = false

        if let lane = lanes[key] {
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

                lanes[key] = Lane(
                    id: replacement.id,
                    task: replacement.task,
                    waiters: lane.waiters
                )

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
                lanes[key]?.pendingOperation = operation
                waitsOnRerun = true
            }
        } else {
            let started = start(
                key,
                operation
            )

            lanes[key] = Lane(
                id: started.id,
                task: started.task,
                waiters: [:]
            )
        }

        return await wait(
            on: key,
            as: waiterID,
            abandonable: abandonable,
            pending: waitsOnRerun
        )
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
            do throws(Exception) {
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

    /// Suspends until the lane for `key` settles.
    ///
    /// Registration happens synchronously before the first suspension,
    /// so a lane installed in the current actor turn cannot settle or
    /// be replaced before this waiter is attached to it.
    private func wait(
        on key: Key,
        as waiterID: UUID,
        abandonable: Bool,
        pending: Bool
    ) async -> Settlement? {
        guard abandonable else {
            return await withCheckedContinuation { continuation in
                register(
                    continuation,
                    on: key,
                    as: waiterID,
                    pending: pending
                )
            }
        }

        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                register(
                    continuation,
                    on: key,
                    as: waiterID,
                    pending: pending
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
