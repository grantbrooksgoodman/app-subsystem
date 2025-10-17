//
//  MetadataProtocol.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public protocol MetadataProtocol: Hashable {
    // MARK: - Properties

    var fileName: String { get }
    var function: String { get }
    var line: Int { get }
    var sender: Any { get }

    // MARK: - Computed Properties

    var id: String { get }
}
