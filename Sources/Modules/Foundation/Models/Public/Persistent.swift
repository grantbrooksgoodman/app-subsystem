//
//  Persistent.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// Property wrapper for persisting values in `UserDefaults`.
@propertyWrapper
public final class Persistent<T: Codable> {
    // MARK: - Dependencies

    @Dependency(\.userDefaults) private var defaults: UserDefaults
    @Dependency(\.jsonDecoder) private var jsonDecoder: JSONDecoder
    @Dependency(\.jsonEncoder) private var jsonEncoder: JSONEncoder

    // MARK: - Properties

    private let key: UserDefaultsKey

    // MARK: - Init

    public init(_ key: UserDefaultsKey) {
        self.key = key
    }

    // MARK: - WrappedValue

    public var wrappedValue: T? {
        get {
            guard let data = defaults.value(forKey: key) as? Data,
                  let decoded: T = try? jsonDecoder.decode(T.self, from: data) else {
                return defaults.value(forKey: key) as? T
            }

            return decoded
        }
        set {
            guard let encoded = try? jsonEncoder.encode(newValue) else {
                defaults.set(newValue, forKey: key)
                return
            }

            defaults.set(encoded, forKey: key)
        }
    }
}
