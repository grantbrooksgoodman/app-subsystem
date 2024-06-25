//
//  CacheDomainListDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension AppSubsystem.Delegates {
    protocol CacheDomainListDelegate {
        var appCacheDomains: [CacheDomain] { get }
    }

    struct DefaultCacheDomainListDelegate: CacheDomainListDelegate {
        public let appCacheDomains = CacheDomain.subsystemCases
    }
}
