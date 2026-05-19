//
//  UIDevice+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

public extension UIDevice {
    /// A Boolean value indicating whether the app is running in the
    /// Simulator.
    static let isSimulator: Bool = {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }()
}
