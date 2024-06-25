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
        var allCacheDomains: [CacheDomain] { get }
    }

    struct DefaultCacheDomainListDelegate: CacheDomainListDelegate {
        public var allCacheDomains: [CacheDomain] {
            [
                .encodedHash,
                .localTranslationArchive,
            ]
        }
    }
}
