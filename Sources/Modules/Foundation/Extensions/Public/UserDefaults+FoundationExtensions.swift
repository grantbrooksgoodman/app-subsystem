//
//  UserDefaults+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension UserDefaults {
    // MARK: - Types

    enum KeyPreservationStrategy {
        /* MARK: Cases */

        case custom([UserDefaultsKey])
        case none
        case permanentAndSubsystemKeys(plus: [UserDefaultsKey]? = nil)
        case subsystemKeys(plus: [UserDefaultsKey]? = nil)

        /* MARK: Properties */

        fileprivate var keys: [UserDefaultsKey] {
            switch self {
            case let .custom(keys):
                return keys.unique

            case .none:
                return []

            case let .permanentAndSubsystemKeys(plus: additionalKeys):
                let additionalKeys = additionalKeys ?? []
                let permanentKeys = AppSubsystem.delegates.permanentUserDefaultsKeys?.permanentKeys ?? []
                return (additionalKeys + permanentKeys + UserDefaultsKey.subsystemKeys).unique

            case let .subsystemKeys(plus: additionalKeys):
                return ((additionalKeys ?? []) + UserDefaultsKey.subsystemKeys).unique
            }
        }
    }

    // MARK: - Methods

    /// Removes the value of the specified default key.
    func removeObject(forKey defaultName: UserDefaultsKey) {
        removeObject(forKey: defaultName.rawValue)
    }

    func reset(preserving: KeyPreservationStrategy = .permanentAndSubsystemKeys()) {
        let dictionary = dictionaryRepresentation()
        let preservedValues = preserving.keys.reduce(into: [String: Any]()) { partialResult, key in
            if let value = value(forKey: key.rawValue) {
                partialResult[key.rawValue] = value
            }
        }

        dictionary.keys.forEach { removeObject(forKey: $0) }
        for (key, value) in preservedValues {
            set(value, forKey: key)
        }
    }

    /// Sets the value of the specified default key.
    func set(_ value: Any?, forKey defaultName: UserDefaultsKey) {
        set(value, forKey: defaultName.rawValue)
    }

    /// Returns the value for the property identified by a given key.
    func value(forKey key: UserDefaultsKey) -> Any? {
        value(forKey: key.rawValue)
    }
}
