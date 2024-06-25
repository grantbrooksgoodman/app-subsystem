//
//  Effect+Cancellation.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public typealias CancelID = Hashable & Sendable

public extension Effect {
    static func cancel(id: some CancelID) -> Self {
        .fireAndForget {
            await internalCancellableTasks.cancel(id: id)
        }
    }

    static func cancel(id: Any.Type) -> Self {
        .cancel(id: ObjectIdentifier(id))
    }

    static func cancel(ids: [some CancelID]) -> Self {
        .merge(ids.map(Effect.cancel(id:)))
    }

    static func cancel(ids: [Any.Type]) -> Self {
        .merge(ids.map(Effect.cancel(id:)))
    }

    func cancellable(id: some CancelID, cancelInFlight: Bool = false) -> Self {
        .run { send in
            await withTaskCancellation(id: id, cancelInFlight: cancelInFlight) {
                await operation(send)
            }
        }
    }

    func cancellable(id: Any.Type, cancelInFlight: Bool = false) -> Self {
        cancellable(id: ObjectIdentifier(id), cancelInFlight: cancelInFlight)
    }
}

public func withTaskCancellation<T: Sendable>(
    id: some CancelID,
    cancelInFlight: Bool = false,
    operation: @Sendable @escaping () async -> T,
    isolation: isolated (any Actor)? = #isolation
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

public func withTaskCancellation<T: Sendable>(
    id: Any.Type,
    cancelInFlight: Bool = false,
    operation: @Sendable @escaping () async -> T,
    isolation: isolated (any Actor)? = #isolation
) async -> T {
    await withTaskCancellation(
        id: ObjectIdentifier(id),
        cancelInFlight: cancelInFlight,
        operation: operation
    )
}

public extension Task where Success == Never, Failure == Never {
    static func cancel(id: Any.Type) async {
        await cancel(id: ObjectIdentifier(id))
    }

    static func cancel(id: some CancelID) async {
        await internalCancellableTasks.cancel(id: id)
    }
}

struct InternalCancelID: Hashable {
    // MARK: - Properties

    let discriminator: ObjectIdentifier
    let id: AnyHashable

    // MARK: - Init

    public init(id: AnyHashable) {
        self.id = id
        discriminator = ObjectIdentifier(type(of: id.base))
    }
}

var internalCancellableTasks = CancellableTasks()

actor CancellableTasks {
    // MARK: - Properties

    var storage: [InternalCancelID: Set<AnyTask>] = [:]

    // MARK: - Computed Properties

    public var count: Int { storage.count }

    // MARK: - Methods

    public func exists(at id: AnyHashable) -> Bool { storage[InternalCancelID(id: id)] != nil }

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
