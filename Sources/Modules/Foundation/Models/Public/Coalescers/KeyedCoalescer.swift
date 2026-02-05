//
//  KeyedCoalescer.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// Coalesces concurrent callers onto a single in-flight execution pathway per-key.
/// The slot for `key` is cleared automatically when the in-flight task completes,
/// even if callers are cancelled.
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
