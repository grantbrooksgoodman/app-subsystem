//
//  LoggerDomainSubscriptionDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension AppSubsystem.Delegates {
    protocol LoggerDomainSubscriptionDelegate {
        var domainsExcludedFromSessionRecord: [LoggerDomain] { get }
        var subscribedDomains: [LoggerDomain] { get }
    }

    struct DefaultLoggerDomainSubscriptionDelegate: LoggerDomainSubscriptionDelegate {
        public let domainsExcludedFromSessionRecord = [LoggerDomain]()
        public let subscribedDomains: [LoggerDomain] = [
            .alertKit,
            .caches,
            .general,
            .observer,
            .translation,
        ]
    }
}
