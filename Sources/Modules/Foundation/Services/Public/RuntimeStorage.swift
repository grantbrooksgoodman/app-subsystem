//
//  RuntimeStorage.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public actor RuntimeStorage {
    // MARK: - Properties

    @LockIsolated private static var storedItems = [String: Any]()

    // MARK: - Removal

    public static func remove(_ item: StoredItemKey) {
        storedItems[item.rawValue] = nil
    }

    // MARK: - Retrieval

    public static func retrieve(_ item: StoredItemKey) -> Any? {
        guard let object = storedItems[item.rawValue] else { return nil }
        return object
    }

    // MARK: - Storage

    public static func store(_ object: Any, as item: StoredItemKey) {
        storedItems[item.rawValue] = object
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
