//
//  RuntimeStorage.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public enum RuntimeStorage {
    // MARK: - Properties

    private static let storedItems = LockIsolated<[String: Any]>(wrappedValue: [:])

    // MARK: - Removal

    public static func remove(_ item: StoredItemKey) {
        storedItems.projectedValue[item.rawValue] = nil
    }

    // MARK: - Retrieval

    public static func retrieve(_ item: StoredItemKey) -> Any? {
        storedItems.projectedValue[item.rawValue]
    }

    // MARK: - Storage

    public static func store(_ object: Any, as item: StoredItemKey) {
        storedItems.projectedValue[item.rawValue] = object
    }
}

public extension RuntimeStorage {
    // MARK: - Properties

    static var languageCode: String { getLanguageCode() }
    static var languageCodeDictionary: [String: String]? { getLanguageCodeDictionary() }

    // MARK: - Functions

    private static func getLanguageCode() -> String {
        guard let overridden = retrieve(.overriddenLanguageCode) as? String else { return retrieve(.languageCode) as? String ?? Locale.systemLanguageCode }
        return overridden
    }

    private static func getLanguageCodeDictionary() -> [String: String]? {
        retrieve(.languageCodeDictionary) as? [String: String]
    }
}
