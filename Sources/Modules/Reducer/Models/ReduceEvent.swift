//
//  ReduceEvent.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public enum ReduceEvent<Action, Feedback>: Sendable where Action: Sendable, Feedback: Sendable {
    // MARK: - Cases

    case action(Action)
    case feedback(Feedback)

    // MARK: - Properties

    var action: Action? {
        switch self {
        case let .action(action):
            return action

        case .feedback:
            return nil
        }
    }

    var feedback: Feedback? {
        switch self {
        case .action:
            return nil

        case let .feedback(feedback):
            return feedback
        }
    }
}
