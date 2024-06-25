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

    public let rawValue: String

    public static var allCases: [CacheDomain] { AppSubsystem.delegates.cacheDomainList.allCacheDomains }

    // MARK: - Init

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}
