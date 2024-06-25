//
//  DependencyKey.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public protocol DependencyKey {
    // MARK: - Associated Types

    associatedtype Value

    // MARK: - Methods

    static func resolve(_ dependencies: DependencyValues) -> Value
}
