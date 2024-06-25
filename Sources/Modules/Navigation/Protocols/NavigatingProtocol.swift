//
//  NavigatingProtocol.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

public protocol Navigating {
    // MARK: - Associated Types

    associatedtype Route
    associatedtype State: NavigatorState

    // MARK: - Methods

    func navigate(to route: Route, on state: inout State)
}
