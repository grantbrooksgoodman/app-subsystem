//
//  Task+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension Task {
    /// Awaits the task's result, abandoning the wait – without
    /// cancelling the task – if the calling task is cancelled.
    ///
    /// Unlike `result`, which always waits for the task to complete,
    /// this method returns as soon as *either* the task settles or
    /// the calling task is cancelled. The awaited task itself never
    /// receives a cancellation signal from this method; it continues
    /// running so that other interested parties can still receive
    /// its result.
    ///
    /// If the calling task is already cancelled when this method is
    /// invoked, a `CancellationError` is thrown immediately.
    ///
    /// - Warning: Each abandoned wait leaves behind a lightweight
    ///   observer task that lives until the awaited task settles.
    ///   Ensure awaited tasks are bounded in duration – by a timeout,
    ///   for example – to avoid accumulating observers indefinitely.
    ///
    /// - Returns: The task's settled result.
    ///
    /// - Throws: A `CancellationError` if the calling task was
    ///   cancelled before the awaited task settled.
    func abandonableResult() async throws(_Concurrency.CancellationError) -> Result<Success, Failure> {
        let awaiter = AbandonableAwait<Result<Success, Failure>>()

        do {
            return try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Result<Success, Failure>, any Error>) in
                    awaiter.register(continuation)

                    Task<Void, Never> {
                        await awaiter.settle(returning: self.result)
                    }
                }
            } onCancel: {
                awaiter.abandon()
            }
        } catch {
            throw _Concurrency.CancellationError()
        }
    }
}

public extension Task where Failure == Error {
    /// Runs an operation on a background-priority task, optionally
    /// after a delay.
    @discardableResult
    static func background(
        delayedBy duration: Duration = .zero,
        @_implicitSelfCapture operation: @escaping @Sendable () async throws -> Success
    ) -> Task {
        Task(priority: .background) {
            guard duration != .zero else { return try await operation() }
            try await Task<Never, Never>.sleep(nanoseconds: .init(duration.timeInterval * 1_000_000_000))
            return try await operation()
        }
    }

    /// Runs an operation after the given delay.
    @discardableResult
    static func delayed(
        by duration: Duration,
        priority: TaskPriority? = nil,
        @_implicitSelfCapture operation: @escaping @Sendable () async throws -> Success
    ) -> Task {
        Task(priority: priority) {
            try await Task<Never, Never>.sleep(nanoseconds: .init(duration.timeInterval * 1_000_000_000))
            return try await operation()
        }
    }
}

public extension Task where Failure == Never {
    /// Awaits the task's value, abandoning the wait – without
    /// cancelling the task – if the calling task is cancelled.
    ///
    /// Unlike `value`, which always waits for the task to complete,
    /// this method returns as soon as *either* the task settles or
    /// the calling task is cancelled. The awaited task itself never
    /// receives a cancellation signal from this method; it continues
    /// running so that other interested parties can still receive
    /// its result.
    ///
    /// If the calling task is already cancelled when this method is
    /// invoked, a `CancellationError` is thrown immediately.
    ///
    /// - Warning: Each abandoned wait leaves behind a lightweight
    ///   observer task that lives until the awaited task settles.
    ///   Ensure awaited tasks are bounded in duration – by a timeout,
    ///   for example – to avoid accumulating observers indefinitely.
    ///
    /// - Returns: The task's value.
    ///
    /// - Throws: A `CancellationError` if the calling task was
    ///   cancelled before the awaited task settled.
    func abandonableValue() async throws(_Concurrency.CancellationError) -> Success {
        try await abandonableResult().get()
    }
}

public extension Task where Success == Void, Failure == Never {
    /// Debounces an async operation by `key`, scheduling it to run after `duration`.
    ///
    /// Each call registers a new pending `Task` for the provided `key`. If another call is made with the
    /// same `key` before the delay elapses, the previously registered task for that key is cancelled and
    /// replaced. This yields “latest call wins” behavior: after a burst of calls, `operation` runs at most
    /// once, using the most recently scheduled invocation.
    ///
    /// Internally, the method:
    /// - Creates a new task that waits for `duration` using a cancellation-aware sleep.
    /// - Exits early if the task was cancelled during the delay.
    /// - Runs `operation`.
    /// - Removes the registry entry for `key` only if it still corresponds to this task (via a UUID token),
    ///   preventing an older task from clearing a newer task’s registration.
    ///
    /// - Parameters:
    ///   - key: Identifier used to group and debounce calls. Calls with different keys debounce independently.
    ///   - duration: How long to wait before executing `operation`.
    ///   - priority: The priority used when creating the debounced task.
    ///   - operation: The async operation to run after the delay if not superseded by a later call.
    ///
    /// - Returns: The newly created debounced task. Cancelling the returned task will prevent `operation`
    ///   from running if it has not yet begun.
    ///
    /// - Note: Debouncing is global to the `TaskRegistry` backing this extension. Any call site using the
    ///   same `key` will participate in the same debounce “lane”.
    @discardableResult
    static func debounced(
        _ key: some Hashable & Sendable,
        delay duration: Duration,
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async -> Void
    ) -> Task<Void, Never> {
        let token = UUID()
        let task = Task(priority: priority) {
            // Cancellation-aware delay.
            try? await _Concurrency.Task.sleep(for: duration)
            guard !_Concurrency.Task.isCancelled else {
                Logger.log(
                    .init(
                        "Task was cancelled in the time it took to sleep.",
                        isReportable: false,
                        userInfo: [
                            "DurationMilliseconds": duration.milliseconds,
                            "Key": key,
                            "TaskID": token.uuidString,
                        ],
                        metadata: .init(sender: self)
                    ),
                    domain: .concurrency
                )

                return
            }

            await operation()
            await TaskRegistry.shared.clearIfTokenMatches(
                token,
                for: key
            )
        }

        Task {
            await TaskRegistry.shared.set(
                task,
                token: token,
                for: key
            )
        }

        return task
    }
}

/// A single-resume settlement arbiter for an abandonable await.
///
/// `AbandonableAwait` guarantees that its continuation is resumed
/// exactly once, regardless of how registration, settlement, and
/// abandonment interleave. Cancellation may fire before the
/// continuation is even registered – `withTaskCancellationHandler`
/// invokes its handler immediately when the calling task is already
/// cancelled – so the state machine records an early abandonment and
/// applies it upon registration.
private final class AbandonableAwait<Value: Sendable>: Sendable {
    // MARK: - Types

    private enum State {
        case abandoned
        case pending
        case registered(CheckedContinuation<Value, any Error>)
        case settled
    }

    // MARK: - Properties

    private let state = LockIsolated<State>(.pending)

    // MARK: - Methods

    fileprivate func abandon() {
        let continuation = state.projectedValue.withValue { state -> CheckedContinuation<Value, any Error>? in
            switch state {
            case .abandoned,
                 .settled:
                return nil

            case .pending:
                state = .abandoned
                return nil

            case let .registered(continuation):
                state = .settled
                return continuation
            }
        }

        continuation?.resume(throwing: CancellationError())
    }

    fileprivate func register(
        _ continuation: CheckedContinuation<Value, any Error>
    ) {
        let wasAbandoned = state.projectedValue.withValue { state -> Bool in
            switch state {
            case .abandoned:
                state = .settled
                return true

            case .pending:
                state = .registered(continuation)
                return false

            // Unreachable – registration occurs exactly once.
            case .registered,
                 .settled:
                return false
            }
        }

        guard wasAbandoned else { return }
        continuation.resume(throwing: CancellationError())
    }

    fileprivate func settle(
        returning value: Value
    ) {
        let continuation = state.projectedValue.withValue { state -> CheckedContinuation<Value, any Error>? in
            guard case let .registered(continuation) = state else { return nil }
            state = .settled
            return continuation
        }

        continuation?.resume(returning: value)
    }
}

private actor TaskRegistry {
    // MARK: - Types

    private struct Entry {
        /* MARK: Properties */

        fileprivate let task: Task<Void, Never>
        fileprivate let token: UUID

        /* MARK: Init */

        fileprivate init(
            _ token: UUID,
            task: Task<Void, Never>
        ) {
            self.token = token
            self.task = task
        }
    }

    // MARK: - Properties

    fileprivate static let shared = TaskRegistry()

    private var tasks: [AnyHashable: Entry] = [:]

    // MARK: - Methods

    fileprivate func clearIfTokenMatches(
        _ token: UUID,
        for key: some Hashable & Sendable
    ) {
        let key = AnyHashable(key)
        // Clear only if we are still the latest task registered for this key.
        guard tasks[key]?.token == token else { return }
        tasks[key] = nil
    }

    fileprivate func set(
        _ task: Task<Void, Never>,
        token: UUID,
        for key: some Hashable & Sendable
    ) {
        let key = AnyHashable(key)
        tasks[key]?.task.cancel()
        tasks[key] = .init(
            token,
            task: task
        )
    }
}
