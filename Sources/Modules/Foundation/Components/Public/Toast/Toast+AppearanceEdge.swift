//
//  Toast+AppearanceEdge.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension Toast {
    /// The screen edge from which a banner toast slides into view.
    enum AppearanceEdge: Equatable, Sendable {
        /// The banner appears from the bottom of the screen.
        case bottom

        /// The banner appears from the top of the screen.
        case top
    }
}
