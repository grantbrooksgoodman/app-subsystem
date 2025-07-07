//
//  Collection+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

extension Collection {
    func distance(to index: Index) -> Int { distance(from: startIndex, to: index) }
}
