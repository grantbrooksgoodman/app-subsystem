//
//  UIApplication+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

extension UIApplication {
    static var iOS19IsAvailable: Bool {
        if #available(iOS 19, *) { return true }
        return false
    }
}
