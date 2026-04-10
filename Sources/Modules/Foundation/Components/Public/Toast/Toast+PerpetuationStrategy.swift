//
//  Toast+PerpetuationStrategy.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension Toast {
    enum PerpetuationStrategy: Equatable, Sendable {
        case ephemeral(Duration)
        case persistent
    }
}
