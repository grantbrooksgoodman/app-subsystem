//
//  Cacheable.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public protocol Cacheable {
    // MARK: - Associated Types

    associatedtype CacheKey: RawRepresentable where CacheKey.RawValue: StringProtocol, CacheKey: CaseIterable

    // MARK: - Methods

    func clear()
    func removeObject(forKey key: CacheKey)
    func set(_ value: Any, forKey key: CacheKey)
    func value(forKey key: CacheKey) -> Any?
}
