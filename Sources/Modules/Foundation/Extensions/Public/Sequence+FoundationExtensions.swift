//
//  Sequence+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension Sequence where Iterator.Element: Equatable {
    /// The elements of the sequence with duplicates removed,
    /// preserving order.
    var unique: [Iterator.Element] {
        var uniqueValues = [Iterator.Element]()
        for value in self where !uniqueValues.contains(value) {
            uniqueValues.append(value)
        }
        return uniqueValues
    }
}

public extension Sequence where Iterator.Element: Hashable {
    /// The elements of the sequence with duplicates removed,
    /// preserving order. Uses a hash set for improved performance.
    var unique: [Iterator.Element] {
        var seen = Set<Iterator.Element>()
        return filter { seen.insert($0).inserted }
    }
}
