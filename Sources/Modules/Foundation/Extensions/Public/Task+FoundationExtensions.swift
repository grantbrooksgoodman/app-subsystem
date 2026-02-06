//
//  Task+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension Task where Failure == Error {
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
        _ key: AnyHashable,
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
                    domain: .task
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
        for key: AnyHashable
    ) {
        // Clear only if we are still the latest task registered for this key.
        guard tasks[key]?.token == token else { return }
        tasks[key] = nil
    }

    fileprivate func set(
        _ task: Task<Void, Never>,
        token: UUID,
        for key: AnyHashable
    ) {
        tasks[key]?.task.cancel()
        tasks[key] = .init(
            token,
            task: task
        )
    }
}
