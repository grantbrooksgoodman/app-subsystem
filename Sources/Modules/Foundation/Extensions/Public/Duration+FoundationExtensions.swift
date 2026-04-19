//
//  Duration+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension Duration {
    /// The duration expressed in milliseconds.
    var milliseconds: Double {
        (Double(components.seconds) * 1000) + (Double(components.attoseconds) * 1e-15)
    }

    /// The duration expressed as a `TimeInterval` (seconds).
    var timeInterval: TimeInterval {
        TimeInterval(components.seconds) + (Double(components.attoseconds) * 1e-18)
    }
}
