//
//  Send.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/// A callback used by ``Effect`` operations to send actions back to the
/// reducer.
///
/// `Send` is passed to the closure in ``Effect/run(priority:operation:)``
/// and related methods. Call it like a function to dispatch an action:
///
/// ```swift
/// return .run { send in
///    let items = await service.fetchItems()
///    await send(.itemsLoaded(items))
/// }
/// ```
///
/// You can also send actions with an animation or transaction:
///
///     await send(.toggled, animation: .default)
///
/// `Send` automatically checks for task cancellation before dispatching.
/// If the effect's task has been cancelled, the action is silently
/// dropped.
@MainActor
public struct Send<Action> {
    // MARK: - Properties

    /// The underlying closure that dispatches an action.
    public let send: @MainActor (Action) -> Void

    // MARK: - Init

    public init(send: @escaping @MainActor (Action) -> Void) {
        self.send = send
    }

    // MARK: - Call as Function

    /// Sends an action to the reducer.
    ///
    /// The action is dropped if the current task has been cancelled.
    ///
    /// - Parameter action: The action to send.
    public func callAsFunction(_ action: Action) {
        guard !Task.isCancelled else { return }
        send(action)
    }

    /// Sends an action to the reducer with an animation.
    ///
    /// - Parameters:
    ///   - action: The action to send.
    ///   - animation: The animation to apply to any resulting state
    ///     changes.
    public func callAsFunction(
        _ action: Action,
        animation: Animation?
    ) {
        callAsFunction(
            action,
            transaction: Transaction(animation: animation)
        )
    }

    /// Sends an action to the reducer within a transaction.
    ///
    /// - Parameters:
    ///   - action: The action to send.
    ///   - transaction: The transaction to apply to any resulting state
    ///     changes.
    public func callAsFunction(
        _ action: Action,
        transaction: Transaction
    ) {
        guard !Task.isCancelled else { return }
        withTransaction(transaction) { self(action) }
    }
}
