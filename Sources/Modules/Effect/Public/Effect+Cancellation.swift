//
//  Effect+Cancellation.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A type that can identify a cancellable effect.
///
/// Any `Hashable & Sendable` value can serve as a cancellation identifier.
/// A common pattern is to define an enum of identifiers:
///
/// ```swift
/// private enum CancelIDs {
///    case polling
///    case search
/// }
/// ```
///
/// You can also use a type itself as the identifier by passing it to the
/// overloads that accept `Any.Type`.
public typealias CancelID = Hashable & Sendable

public extension Effect {
    /// Creates an effect that cancels any in-flight effect with the given
    /// identifier.
    ///
    ///     return .cancel(id: CancelIDs.polling)
    ///
    /// - Parameter id: The identifier of the effect to cancel.
    static func cancel(id: some CancelID) -> Self {
        .fireAndForget {
            await internalCancellableTasks.cancel(id: id)
        }
    }

    /// Creates an effect that cancels any in-flight effect identified by
    /// the given type.
    ///
    ///     return .cancel(id: SearchEffect.self)
    ///
    /// - Parameter id: The type to use as the cancellation identifier.
    static func cancel(id: Any.Type) -> Self {
        .cancel(id: ObjectIdentifier(id))
    }

    /// Creates an effect that cancels all in-flight effects matching the
    /// given identifiers.
    ///
    /// - Parameter ids: The identifiers of the effects to cancel.
    static func cancel(ids: [some CancelID]) -> Self {
        .merge(ids.map(Effect.cancel(id:)))
    }

    /// Creates an effect that cancels all in-flight effects matching the
    /// given types.
    ///
    /// - Parameter ids: The types to use as cancellation identifiers.
    static func cancel(ids: [Any.Type]) -> Self {
        .merge(ids.map(Effect.cancel(id:)))
    }

    /// Marks this effect with an identifier so it can be cancelled later.
    ///
    /// Use `cancellable` together with ``cancel(id:)`` to manage
    /// the lifetime of long-running effects:
    ///
    /// ```swift
    /// case .startPolling:
    ///    return .run { send in
    ///        for await _ in clock.timer(interval: .seconds(5)) {
    ///            await send(.poll)
    ///        }
    ///    }
    ///    .cancellable(id: CancelIDs.polling)
    ///
    /// case .stopPolling:
    ///    return .cancel(id: CancelIDs.polling)
    /// ```
    ///
    /// - Parameters:
    ///   - id: The identifier to associate with this effect.
    ///   - cancelInFlight: When `true`, any previously running effect with
    ///     the same identifier is cancelled before this one starts. This
    ///     is useful for search-as-you-type patterns where only the most
    ///     recent request matters. Defaults to `false`.
    func cancellable(
        id: some CancelID,
        cancelInFlight: Bool = false
    ) -> Self {
        .run { send in
            await withTaskCancellation(id: id, cancelInFlight: cancelInFlight) {
                await operation(send)
            }
        }
    }

    /// Marks this effect with a type identifier so it can be cancelled
    /// later.
    ///
    /// - Parameters:
    ///   - id: The type to use as the cancellation identifier.
    ///   - cancelInFlight: When `true`, any previously running effect with
    ///     the same identifier is cancelled before this one starts.
    ///     Defaults to `false`.
    func cancellable(id: Any.Type, cancelInFlight: Bool = false) -> Self {
        cancellable(id: ObjectIdentifier(id), cancelInFlight: cancelInFlight)
    }
}

/// Runs an asynchronous operation that can be cancelled by its identifier.
///
/// Use this function outside of a reducer when you need cancellable async
/// work that participates in the same cancellation registry as
/// ``Effect.cancellable(id:cancelInFlight:)``:
///
/// ```swift
/// let result = await withTaskCancellation(id: CancelIDs.search) {
///    await service.search(query)
/// }
/// ```
///
/// - Parameters:
///   - id: The identifier to associate with this operation.
///   - cancelInFlight: When `true`, any previously running operation with
///     the same identifier is cancelled before this one starts. Defaults
///     to `false`.
///   - operation: The asynchronous work to perform.
///   - isolation: The actor isolation context. Defaults to the caller's
///     isolation.
///
/// - Returns: The value produced by `operation`.
public func withTaskCancellation<T: Sendable>(
    id: some CancelID,
    cancelInFlight: Bool = false,
    operation: @Sendable @escaping () async -> T,
    isolation: isolated(any Actor)? = #isolation
) async -> T {
    if cancelInFlight { await internalCancellableTasks.cancel(id: id) }

    let task = Task { await operation() }
    await internalCancellableTasks.insert(task, at: id)

    let value = await withTaskCancellationHandler {
        await task.value
    } onCancel: {
        task.cancel()
    }

    await internalCancellableTasks.remove(task, at: id)
    return value
}

/// Runs an asynchronous operation that can be cancelled by a type
/// identifier.
///
/// - Parameters:
///   - id: The type to use as the cancellation identifier.
///   - cancelInFlight: When `true`, any previously running operation with
///     the same identifier is cancelled before this one starts. Defaults
///     to `false`.
///   - operation: The asynchronous work to perform.
///   - isolation: The actor isolation context. Defaults to the caller's
///     isolation.
///
/// - Returns: The value produced by `operation`.
public func withTaskCancellation<T: Sendable>(
    id: Any.Type,
    cancelInFlight: Bool = false,
    operation: @Sendable @escaping () async -> T,
    isolation: isolated(any Actor)? = #isolation
) async -> T {
    await withTaskCancellation(
        id: ObjectIdentifier(id),
        cancelInFlight: cancelInFlight,
        operation: operation
    )
}

public extension Task where Success == Never, Failure == Never {
    /// Cancels any in-flight cancellable task identified by the given type.
    ///
    /// - Parameter id: The type to use as the cancellation identifier.
    static func cancel(id: Any.Type) async {
        await cancel(id: ObjectIdentifier(id))
    }

    /// Cancels any in-flight cancellable task with the given identifier.
    ///
    /// - Parameter id: The identifier of the task to cancel.
    static func cancel(id: some CancelID) async {
        await internalCancellableTasks.cancel(id: id)
    }
}

struct InternalCancelID: Hashable {
    // MARK: - Properties

    let discriminator: ObjectIdentifier
    let id: AnyHashable

    // MARK: - Init

    init(id: AnyHashable) {
        self.id = id
        discriminator = ObjectIdentifier(type(of: id.base))
    }
}

let internalCancellableTasks = CancellableTasks()

actor CancellableTasks {
    // MARK: - Properties

    var storage: [InternalCancelID: Set<AnyTask>] = [:]

    // MARK: - Computed Properties

    var count: Int { storage.count }

    // MARK: - Methods

    func exists(at id: AnyHashable) -> Bool { storage[InternalCancelID(id: id)] != nil }

    func cancel(id: AnyHashable) {
        let cancelID = InternalCancelID(id: id)
        storage[cancelID]?.forEach { $0.cancel() }
        storage[cancelID] = nil
    }

    func insert(
        _ task: Task<some Any, some Any>,
        at id: AnyHashable
    ) {
        let cancelID = InternalCancelID(id: id)
        storage[cancelID, default: []].insert(AnyTask(task))
    }

    func remove(
        _ task: Task<some Any, some Any>,
        at id: AnyHashable
    ) {
        let cancelID = InternalCancelID(id: id)
        storage[cancelID]?.remove(AnyTask(task))

        if storage[cancelID]?.isEmpty == true {
            storage[cancelID] = nil
        }
    }
}
