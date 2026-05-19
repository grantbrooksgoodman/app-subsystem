//
//  Cache.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A property wrapper that stores and retrieves values from an
/// in-memory cache backed by `NSCache`.
///
/// Use `@Cached` to add transparent caching to a property. The wrapper
/// is generic over two types: a `KeyType` that identifies the cached
/// entry, and an `ObjectType` that describes the value being stored:
///
/// ```swift
/// private enum CacheKey: String, CaseIterable {
///     case profileImage
///     case thumbnailImage
/// }
///
/// @Cached(CacheKey.profileImage) var profileImage: UIImage?
/// @Cached(CacheKey.thumbnailImage) var thumbnailImage: UIImage?
/// ```
///
/// Reading the wrapped value returns `nil` when no entry exists for the
/// key. Assigning `nil` removes the entry from the cache.
///
/// ## Memory Pressure
///
/// `@Cached` monitors the app's memory footprint and
/// automatically disables new writes when memory usage reaches one
/// third of the device's total RAM. Writes resume once the footprint
/// drops below that threshold. Because the underlying store is
/// `NSCache`, the system may also evict entries independently under
/// memory pressure.
///
/// ## Diagnostics
///
/// Pass `logsAccess: true` at initialization to emit a log entry for
/// every read, write, and removal. These entries are recorded by the
/// ``Logger`` under the `.caches` domain.
///
/// - SeeAlso: ``Cacheable``, ``CacheDomain``
@propertyWrapper
public struct Cached<KeyType: RawRepresentable & CaseIterable, ObjectType> where KeyType.RawValue: StringProtocol {
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

    /// Creates a cached property for the given key.
    ///
    /// - Parameters:
    ///   - key: The cache key that identifies this entry.
    ///   - logsAccess: A Boolean value that enables diagnostic logging
    ///     for every cache access. The default is `false`.
    public init(
        _ key: KeyType,
        logsAccess: Bool = false
    ) {
        self.key = key
        self.logsAccess = logsAccess
    }

    // MARK: - WrappedValue

    /// The cached value, or `nil` if no entry exists for the key.
    ///
    /// Assigning a non-nil value stores it in the cache, subject to
    /// the memory pressure check. Assigning `nil` removes the entry.
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
            sender: self
        )
    }
}

private enum Cache {
    // MARK: - Properties

    fileprivate static let didReachMemoryCeiling = LockIsolated<Bool>(false)

    private static let _value = LockIsolated<NSCache<NSString, AnyObject>>(.init())

    // MARK: - Computed Properties

    fileprivate static var value: NSCache<NSString, AnyObject> {
        get { _value.wrappedValue }
        set { _value.wrappedValue = newValue }
    }
}

extension Cached: Cacheable {
    // MARK: - Type Aliases

    public typealias CacheKey = KeyType

    // MARK: - Properties

    private var canCacheNewValue: Bool {
        @Dependency(\.coreKit.utils.appMemoryFootprint) var appMemoryFootprint: Int?
        let currentMemoryUsage = appMemoryFootprint ?? 0
        let memoryUsageCeiling = ((ProcessInfo.processInfo.physicalMemory / 1024) / 1024) / 3

        let newValue = currentMemoryUsage >= memoryUsageCeiling
        let oldValue = Cache.didReachMemoryCeiling.wrappedValue
        Cache.didReachMemoryCeiling.wrappedValue = newValue

        if newValue != oldValue {
            switch newValue {
            case true:
                Logger.log(
                    .init(
                        "Memory ceiling reached; caching disabled until footprint is less than 1/3 of total RAM.",
                        userInfo: ["MemoryFootprintMB": currentMemoryUsage],
                        metadata: .init(sender: AppSubsystem.self)
                    ),
                    domain: .caches
                )

            case false:
                Logger.log(
                    .init(
                        "Memory footprint sufficiently low; caching re-enabled.",
                        userInfo: ["MemoryFootprintMB": currentMemoryUsage],
                        metadata: .init(sender: AppSubsystem.self)
                    ),
                    domain: .caches
                )
            }
        }

        return currentMemoryUsage < memoryUsageCeiling
    }

    // MARK: - Cacheable Conformance

    func clear() {
        CacheKey.allCases.forEach { removeObject(forKey: $0) }
    }

    func removeObject(forKey key: KeyType) {
        guard let keyString = key.rawValue as? NSString else { return }
        Cache.value.removeObject(forKey: keyString)
    }

    func set(
        _ value: Any,
        forKey key: KeyType
    ) {
        guard let keyString = key.rawValue as? NSString,
              canCacheNewValue else { return }
        Cache.value.setObject(value as AnyObject, forKey: keyString)
    }

    func value(forKey key: KeyType) -> Any? {
        guard let keyString = key.rawValue as? NSString else { return nil }
        return Cache.value.object(forKey: keyString)
    }
}
