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
public struct Send<Feedback> {
    // MARK: - Properties

    public let send: @MainActor (Feedback) -> Void

    // MARK: - Init

    public init(send: @escaping @MainActor (Feedback) -> Void) {
        self.send = send
    }

    // MARK: - Call as Function

    public func callAsFunction(_ feedback: Feedback) {
        guard !Task.isCancelled else { return }
        send(feedback)
    }

    public func callAsFunction(_ feedback: Feedback, animation: Animation?) {
        callAsFunction(feedback, transaction: Transaction(animation: animation))
    }

    public func callAsFunction(_ feedback: Feedback, transaction: Transaction) {
        guard !Task.isCancelled else { return }
        withTransaction(transaction) { self(feedback) }
    }
}
