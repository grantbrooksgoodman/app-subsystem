//
//  Send.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

@MainActor
public struct Send<Action> {
    // MARK: - Properties

    public let send: @MainActor (Action) -> Void

    // MARK: - Init

    public init(send: @escaping @MainActor (Action) -> Void) {
        self.send = send
    }

    // MARK: - Call as Function

    public func callAsFunction(_ action: Action) {
        guard !Task.isCancelled else { return }
        send(action)
    }

    public func callAsFunction(_ action: Action, animation: Animation?) {
        callAsFunction(action, transaction: Transaction(animation: animation))
    }

    public func callAsFunction(_ action: Action, transaction: Transaction) {
        guard !Task.isCancelled else { return }
        withTransaction(transaction) { self(action) }
    }
}
