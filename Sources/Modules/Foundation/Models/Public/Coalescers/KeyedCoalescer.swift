//
//  KeyedCoalescer.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A per-key async work coordinator that deduplicates concurrent callers.
///
/// `KeyedCoalescer` ensures there is at most one in-flight `operation` per `key`.
/// If multiple callers invoke the coalescer with the same `key` while an operation
/// is running, they will await the existing task and share its result. Calls for
/// different keys proceed independently.
///
/// The slot for `key` is cleared automatically when the in-flight task completes,
/// independent of which caller awaits it or whether callers are cancelled.
public actor KeyedCoalescer<Key: Hashable & Sendable, Output: Sendable> {
    // MARK: - Type Aliases

    public typealias Operation = @Sendable () async -> Output

    // MARK: - Properties

    private var currentTasks: [
        Key: (id: UUID, task: Task<Output, Never>)
    ] = [:]

    // MARK: - Init

    public init() {}

    // MARK: - Call as Function

    public func callAsFunction(
        _ key: Key,
        _ operation: @escaping Operation
    ) async -> Output {
        if let existingTask = currentTasks[key] {
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
                domain: .task
            )

            return await existingTask.task.value
        }

        let id = UUID()
        let task = Task { await operation() }
        currentTasks[key] = (id: id, task: task)

        // Always-clear finisher; runs regardless of who awaits/cancels.
        Task { [id] in
            _ = await task.value
            self.clearIfMatches(
                key: key,
                id: id
            )
        }

        return await task.value
    }

    // MARK: - Auxiliary

    private func clearIfMatches(
        key: Key,
        id: UUID
    ) {
        guard let existingTask = currentTasks[key],
              existingTask.id == id else { return }

        currentTasks[key] = nil
    }
}
