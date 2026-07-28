//
//  LoggerDomainSubscriptionDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension AppSubsystem.Delegates {
    /// A type that specifies which logger domains the app
    /// subscribes to and which domains are excluded from the session
    /// record.
    ///
    /// Conform to this protocol to control the initial logging
    /// configuration at launch. The subsystem reads your delegate's
    /// values during setup and subscribes to the returned domains
    /// automatically:
    ///
    /// ```swift
    /// struct AppLoggerDomainSubscription: AppSubsystem.Delegates.LoggerDomainSubscriptionDelegate {
    ///     let domainsExcludedFromSessionRecord: [LoggerDomain] = [.networking]
    ///     let subscribedDomains: [LoggerDomain] = [
    ///         .general,
    ///         .networking,
    ///         .persistence,
    ///     ]
    /// }
    /// ```
    ///
    /// If you do not provide a custom conformance, the subsystem uses
    /// ``DefaultLoggerDomainSubscriptionDelegate``, which subscribes
    /// to the built-in domains and excludes none from the session
    /// record.
    ///
    /// - SeeAlso: ``Logger``, ``LoggerDomain``
    protocol LoggerDomainSubscriptionDelegate {
        /// The domains whose output is omitted from the on-disk
        /// session record.
        ///
        /// Messages logged to these domains still appear in the
        /// console, but are not written to the session record file.
        var domainsExcludedFromSessionRecord: [LoggerDomain] { get }

        /// The domains the logger subscribes to at launch.
        ///
        /// Only messages logged to a subscribed domain produce
        /// output. Domains not in this list are silently ignored
        /// unless subscribed to later at runtime.
        var subscribedDomains: [LoggerDomain] { get }
    }

    /// The default logger domain subscription, which subscribes to
    /// all built-in subsystem domains and excludes none from the
    /// session record.
    struct DefaultLoggerDomainSubscriptionDelegate: LoggerDomainSubscriptionDelegate {
        public let domainsExcludedFromSessionRecord = [LoggerDomain]()
        public let subscribedDomains: [LoggerDomain] = [
            .alertKit,
            .caches,
            .concurrency,
            .general,
            .localization,
            .translation,
        ]
    }
}
