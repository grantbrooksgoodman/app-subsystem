//
//  Notification+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension Notification.Name {
    /// Posted when a `UIAlertController` is dismissed.
    static let uiAlertControllerDismissed: Notification.Name = .init(rawValue: "uiAlertControllerDismissed")
}
