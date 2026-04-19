//
//  Effect.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A description of work to perform in response to a reducer action.
///
/// When a ``Reducer`` receives an action, it returns an `Effect` that
/// describes any asynchronous work that should follow the state change.
/// The runtime executes the effect and dispatches any resulting actions back
/// into the reducer.
///
/// ## Creating Effects
///
/// Use one of the provided type methods to create an effect:
///
/// - ``none`` when no work is needed.
/// - ``run(priority:operation:)`` to perform async work that may send
///   one or more actions back through a ``Send`` callback.
/// - ``fireAndForget(priority:operation:)`` to perform async work that
///   does not produce actions.
/// - ``task(priority:delay:operation:)`` to perform async work that
///   returns a single optional action.
///
/// ```swift
/// func reduce(into state: inout State, action: Action) -> Effect<Action> {
///     switch action {
///     case .refresh:
///         return .run { send in
///             let items = await service.fetchItems()
///             await send(.itemsLoaded(items))
///         }
///
///     case .itemsLoaded(let items):
///         state.items = items
///         return .none
///     }
/// }
/// ```
///
/// ## Combining Effects
///
/// Use ``merge(_:)`` to run multiple effects in parallel:
///
/// ```swift
/// return .merge(
///    .fireAndForget { await analytics.track(.refreshed) },
///    .task { await .itemsLoaded(service.fetchItems()) }
/// )
/// ```
///
/// ## Cancellation
///
/// Mark long-running effects with ``cancellable(id:cancelInFlight:)`` and
/// cancel them later with ``cancel(id:)``:
///
/// ```swift
/// case .startPolling:
///    return .run { send in
///        for await tick in clock.timer(interval: .seconds(5)) {
///            await send(.poll)
///        }
///    }
///    .cancellable(id: CancelIDs.polling)
///
/// case .stopPolling:
///    return .cancel(id: CancelIDs.polling)
/// ```
///
/// ## Dependency Scope
///
/// Effects created with ``run(priority:operation:)`` and its variants
/// automatically capture the current dependency scope. Dependencies
/// resolved inside the effect's closure see the same values that were
/// active when the effect was created.
public struct Effect<Action>: Sendable {
    // MARK: - Type Aliases

    /// The signature of an effect's asynchronous operation.
    public typealias Operation = @Sendable (Send<Action>) async -> Void

    // MARK: - Properties

    /// The asynchronous closure that performs this effect's work.
    public let operation: Operation

    /// The task priority to use when scheduling this effect.
    public let priority: TaskPriority?

    // MARK: - Init

    init(
        priority: TaskPriority? = nil,
        operation: @escaping Operation
    ) {
        self.priority = priority
        self.operation = operation
    }
}

public extension Effect {
    // MARK: - Properties

    /// A no-op effect.
    ///
    /// Return `.none` from a reducer when a state change does not require
    /// any follow-up work:
    ///
    /// ```swift
    /// case .buttonTapped:
    ///    state.count += 1
    ///    return .none
    /// ```
    ///
    static var none: Self { .init { _ in } }

    // MARK: - Fire & Forget

    /// Creates an effect that performs asynchronous work without producing
    /// actions.
    ///
    /// Use `fireAndForget` for side effects that do not feed information
    /// back into the reducer, such as analytics or logging:
    ///
    /// ```swift
    /// return .fireAndForget {
    ///    await analytics.track(.screenViewed)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - priority: The task priority for the effect. Defaults to `nil`.
    ///   - operation: The asynchronous work to perform.
    static func fireAndForget(
        priority: TaskPriority? = nil,
        operation: @Sendable @escaping () async -> Void
    ) -> Self {
        .run(priority: priority) { _ in
            await operation()
        }
    }

    // MARK: - Run

    /// Creates an effect that performs asynchronous work and sends actions
    /// back to the reducer.
    ///
    /// This is the most general-purpose type method. The provided
    /// closure receives a ``Send`` value that can be called zero or more
    /// times to feed actions back into the system:
    ///
    /// ```swift
    /// return .run { send in
    ///    let items = await service.fetchItems()
    ///    await send(.itemsLoaded(items))
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - priority: The task priority for the effect. Defaults to `nil`.
    ///   - operation: The asynchronous work to perform. Call `send` to
    ///     dispatch actions back to the reducer.
    static func run(
        priority: TaskPriority? = nil,
        operation: @escaping Operation
    ) -> Self {
        DependencyScopes.withEscapedDependencies { dependencies in
            self.init(priority: priority) { send in
                await dependencies.withValue {
                    await operation(send)
                }
            }
        }
    }

    /// Creates an effect that sends each element of an asynchronous
    /// sequence as an action.
    ///
    /// Use this overload to bridge an `AsyncSequence` into the reducer:
    ///
    ///     return .run(clock.timer(interval: .seconds(1)).map { _ in .tick })
    ///
    /// The effect completes when the sequence terminates. Cancellation
    /// errors are handled automatically.
    ///
    /// - Warning: Do not pass Combine `AsyncPublisher` or
    ///   `AsyncThrowingPublisher` sequences. Use ``run(priority:operation:)``
    ///   with an explicit `for await` loop instead.
    ///
    /// - Parameters:
    ///   - priority: The task priority for the effect. Defaults to `nil`.
    ///   - sequence: The asynchronous sequence whose elements are sent as
    ///     actions.
    static func run<S: AsyncSequence>(
        priority: TaskPriority? = nil,
        _ sequence: S
    ) -> Self where S.Element == Action, S.Element: Sendable, S: Sendable {
        assert(
            !String(describing: type(of: sequence)).localizedStandardContains("AsyncPublisher") &&
                !String(describing: type(of: sequence)).localizedStandardContains("AsyncThrowingPublisher")
        )

        return .run(priority: priority) { send in
            do {
                for try await action in sequence {
                    await send(action)
                }
            } catch is CancellationError {} catch { fatalError("This sequence should not throw") }
        }
    }

    // MARK: - Task

    /// Creates an effect that performs asynchronous work and sends at most
    /// one action.
    ///
    /// Use `task` for simple operations that produce a single result:
    ///
    /// ```swift
    /// return .task {
    ///    let profile = await service.fetchProfile()
    ///    return .profileLoaded(profile)
    /// }
    /// ```
    ///
    /// Return `nil` from the closure to complete without sending an action.
    ///
    /// Pass a `delay` to defer the work:
    ///
    ///     return .task(delay: .seconds(1)) { .dismissBanner }
    ///
    /// - Parameters:
    ///   - priority: The task priority for the effect. Defaults to `nil`.
    ///   - delay: An optional duration to wait before performing the
    ///     operation. Defaults to `nil`.
    ///   - operation: The asynchronous work to perform. Return an action
    ///     to send to the reducer, or `nil` to complete silently.
    static func task(
        priority: TaskPriority? = nil,
        delay: Duration? = nil,
        operation: @Sendable @escaping () async -> Action?
    ) -> Self {
        .run(priority: priority) { send in
            if let delay {
                try? await Task.sleep(for: delay)
                await performOperation()
            } else {
                await performOperation()
            }

            func performOperation() async {
                if let action = await operation() {
                    await send(action)
                }
            }
        }
    }
}

public extension Effect {
    /// Transforms the actions produced by this effect.
    ///
    /// Use `map` to convert an effect's action type when composing child
    /// reducers into a parent:
    ///
    ///     childEffect.map(ParentAction.child)
    ///
    /// - Parameter toMapAction: A closure that converts the original action
    ///   into the target action type.
    ///
    /// - Returns: An effect that produces the mapped actions.
    func map<MappedAction>(
        _ toMapAction: @Sendable @escaping (Action) -> (MappedAction)
    ) -> Effect<MappedAction> {
        .run { send in
            await operation(
                Send<Action> { action in
                    send(toMapAction(action))
                }
            )
        }
    }
}
