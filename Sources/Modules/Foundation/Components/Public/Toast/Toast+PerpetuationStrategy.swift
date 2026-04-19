//
//  Toast+PerpetuationStrategy.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension Toast {
    /// The strategy that controls how long a toast remains visible.
    enum PerpetuationStrategy: Equatable, Sendable {
        /// The toast auto-dismisses after the given duration.
        case ephemeral(Duration)

        /// The toast remains on screen until the user dismisses it.
        case persistent
    }
}
