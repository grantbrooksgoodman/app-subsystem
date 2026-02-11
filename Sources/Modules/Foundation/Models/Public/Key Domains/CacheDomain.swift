//
//  CacheDomain.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public struct CacheDomain: CaseIterable, Hashable {
    // MARK: - Properties

    public let clear: () -> Void
    public let rawValue: String

    // MARK: - Computed Properties

    public static var allCases: [CacheDomain] {
        (AppSubsystem.delegates.cacheDomainList.appCacheDomains + CacheDomain.subsystemCases).unique
    }

    // MARK: - Init

    public init(_ rawValue: String, clear: @escaping () -> Void) {
        self.rawValue = rawValue
        self.clear = clear
    }

    // MARK: - Equatable Conformance

    public static func == (left: CacheDomain, right: CacheDomain) -> Bool {
        left.rawValue == right.rawValue
    }

    // MARK: - Hashable Conformance

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

extension CacheDomain {
    static var subsystemCases: [CacheDomain] {
        [
            .appIconImage,
            .encodedHash,
            .localization,
            .localTranslationArchive,
        ]
    }
}
