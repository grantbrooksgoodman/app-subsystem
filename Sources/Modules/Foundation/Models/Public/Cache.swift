//
//  Cache.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

private let cache: NSCache<NSString, AnyObject> = .init()

@propertyWrapper
public struct Cached<KeyType: RawRepresentable, ObjectType> where KeyType.RawValue: StringProtocol, KeyType: CaseIterable {
    // MARK: - Types

    private enum LoggingActionType: String {
        case getValue = "Returning"
        case removeValue = "Removing"
        case setValue = "Setting"
    }

    // MARK: - Properties

    private let key: KeyType
    private let logsAccess: Bool

    // MARK: - Init

    public init(
        _ key: KeyType,
        logsAccess: Bool = false
    ) {
        self.key = key
        self.logsAccess = logsAccess
    }

    // MARK: - WrappedValue

    public var wrappedValue: ObjectType? {
        get {
            guard let value = value(forKey: key) as? ObjectType else { return nil }
            log(.getValue, key: key)
            return value
        }

        set {
            guard let newValue else {
                removeObject(forKey: key)
                log(.removeValue, key: key)
                return
            }

            set(newValue, forKey: key)
            log(.setValue, key: key)
        }
    }

    // MARK: - Logging

    private func log(_ type: LoggingActionType, key: KeyType) {
        guard logsAccess else { return }
        Logger.log(
            "\(type.rawValue) cached value for key \"\(key.rawValue)\".",
            domain: .caches,
            metadata: [self, #file, #function, #line]
        )
    }
}

extension Cached: Cacheable {
    // MARK: - Type Aliases

    public typealias CacheKey = KeyType

    // MARK: - Cacheable Conformance

    public func clear() {
        CacheKey.allCases.forEach { removeObject(forKey: $0) }
    }

    public func removeObject(forKey key: KeyType) {
        guard let keyString = key.rawValue as? NSString else { return }
        cache.removeObject(forKey: keyString)
    }

    public func set(_ value: Any, forKey key: KeyType) {
        guard let keyString = key.rawValue as? NSString else { return }
        cache.setObject(value as AnyObject, forKey: keyString)
    }

    public func value(forKey key: KeyType) -> Any? {
        guard let keyString = key.rawValue as? NSString else { return nil }
        return cache.object(forKey: keyString)
    }
}
