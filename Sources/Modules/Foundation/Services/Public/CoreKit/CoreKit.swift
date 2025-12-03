//
//  CoreKit.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public struct CoreKit {
    // MARK: - Properties

    public let gcd: GCD
    public let hud: HUD
    public let ui: UI
    public let utils: Utilities

    // MARK: - Init

    // TODO: AUDIT THIS.
    init(
        gcd: GCD,
        hud: HUD,
        ui: UI,
        utils: Utilities
    ) {
        self.gcd = gcd
        self.hud = hud
        self.ui = ui
        self.utils = utils
    }
}
