//
//  Effect.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public struct Effect<Feedback> {
    // MARK: - Type Aliases

    public typealias Operation = @Sendable (Send<Feedback>) async -> Void

    // MARK: - Properties

    public let operation: Operation
    public let priority: TaskPriority?

    // MARK: - Init

    init(priority: TaskPriority? = nil, operation: @escaping Operation) {
        self.priority = priority
        self.operation = operation
    }
}

public extension Effect {
    // MARK: - Properties

    static var none: Self { .init { _ in } }

    // MARK: - Fire & Forget

    static func fireAndForget(priority: TaskPriority? = nil, operation: @escaping () async -> Void) -> Self {
        .run(priority: priority) { _ in
            await operation()
        }
    }

    // MARK: - Run

    static func run(priority: TaskPriority? = nil, operation: @escaping Operation) -> Self {
        DependencyScopes.withEscapedDependencies { dependencies in
            self.init(priority: priority) { send in
                await dependencies.withValue {
                    await operation(send)
                }
            }
        }
    }

    static func run<S: AsyncSequence>(
        priority: TaskPriority? = nil,
        _ sequence: S
    ) -> Self where S.Element == Feedback, S.Element: Sendable {
        assert(
            !String(describing: type(of: sequence)).localizedStandardContains("AsyncPublisher") &&
                !String(describing: type(of: sequence)).localizedStandardContains("AsyncThrowingPublisher")
        )

        return .run(priority: priority) { send in
            do {
                for try await feedback in sequence {
                    await send(feedback)
                }
            } catch is CancellationError {} catch { fatalError("This sequence should not throw") }
        }
    }

    // MARK: - Task

    static func task(
        priority: TaskPriority? = nil,
        delay: Duration? = nil,
        operation: @Sendable @escaping () async -> Feedback?
    ) -> Self {
        .run(priority: priority) { send in
            if let delay {
                try? await Task.sleep(for: delay)
                await performOperation()
            } else {
                await performOperation()
            }

            func performOperation() async {
                if let feedback = await operation() {
                    await send(feedback)
                }
            }
        }
    }
}

public extension Effect {
    func map<MappedFeedback>(
        _ toMapAction: @escaping (Feedback) -> (MappedFeedback)
    ) -> Effect<MappedFeedback> {
        .run { send in
            await operation(
                Send<Feedback> { feedback in
                    send(toMapAction(feedback))
                }
            )
        }
    }
}
