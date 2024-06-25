//
//  NavigatorStateProtocol.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public protocol NavigatorState {
    // MARK: - Associated Types

    associatedtype ModalPaths: Paths
    associatedtype SeguePaths: Paths
    associatedtype SheetPaths: Paths

    // MARK: - Properties

    var modal: ModalPaths? { get set }
    var sheet: SheetPaths? { get set }
    var stack: [SeguePaths] { get set }
}

public protocol Paths: Hashable, Identifiable {}

public extension Paths {
    var id: String { .init() }
}
