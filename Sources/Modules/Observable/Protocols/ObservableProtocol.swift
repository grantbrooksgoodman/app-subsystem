//
//  ObservableProtocol.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public protocol ObservableProtocol: Sendable {
    // MARK: - Properties

    var key: ObservableKey { get }

    // MARK: - Methods

    func clearObservers()
    func setObservers(_ observers: [any Observer])
}
