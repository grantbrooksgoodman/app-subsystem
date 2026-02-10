//
//  SingleSlotCoalescer.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A single-lane async work coordinator.
///
/// `SingleSlotCoalescer` ensures there is at most one in-flight `operation` at a time.
/// While an operation is running, callers either:
/// - `.coalesce`: await the existing in-flight task and share its result, or
/// - `.lastCallerWins`: cancel the in-flight task and start a new one.
///
/// - Important: `.lastCallerWins` relies on cooperative cancellation. The cancelled
///   `operation` must periodically check for cancellation (or call cancellation-aware APIs)
///   to stop promptly and avoid producing latent side effects.
///
/// The slot is cleared automatically when the in-flight task completes, independent of
/// which caller awaits it or whether callers are cancelled.
public actor SingleSlotCoalescer<Output: Sendable> {
    // MARK: - Type Aliases

    public typealias Operation = @Sendable () async -> Output

    // MARK: - Types

    public enum Mode: Sendable {
        case coalesce
        case lastCallerWins
    }

    // MARK: - Properties

    private var currentTask: (id: UUID, task: Task<Output, Never>)?

    // MARK: - Init

    public init() {}

    // MARK: - Call as Function

    public func callAsFunction(
        mode: Mode = .coalesce,
        _ operation: @escaping Operation
    ) async -> Output {
        switch mode {
        case .coalesce: return await coalesce(operation)
        case .lastCallerWins: return await lastCallerWins(operation)
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
                domain: .task
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
                domain: .task
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
