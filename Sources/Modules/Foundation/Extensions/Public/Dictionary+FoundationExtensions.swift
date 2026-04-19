//
//  Dictionary+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension Dictionary {
    /// Replaces an existing key with a new key, preserving the
    /// associated value.
    mutating func replace(key: Key, with newKey: Key) {
        guard let value = removeValue(forKey: key) else { return }
        self[newKey] = value
    }
}

public extension [String: Any] {
    /// A copy of the dictionary with each key's first letter
    /// uppercased.
    var withCapitalizedKeys: [String: Any] {
        var capitalized = [String: Any]()
        keys.forEach { capitalized[$0.firstUppercase] = self[$0]! }
        return capitalized
    }
}

public extension Dictionary where Value: Equatable {
    /// Returns all keys associated with the given value.
    func keys(for value: Value) -> [Key] {
        filter { $1 == value }.map(\.0)
    }
}
