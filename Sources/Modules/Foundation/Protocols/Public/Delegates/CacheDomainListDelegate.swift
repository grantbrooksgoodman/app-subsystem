//
//  CacheDomainListDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension AppSubsystem.Delegates {
    /// A type that supplies app-specific cache domains to the
    /// subsystem.
    ///
    /// Conform to `CacheDomainListDelegate` and return the cache
    /// domains your app defines. The subsystem merges these
    /// with its own built-in domains so that operations like "clear
    /// all caches" cover the entire app.
    ///
    /// ```swift
    /// struct MyCacheDomains: AppSubsystem.Delegates.CacheDomainListDelegate {
    ///     var appCacheDomains: [CacheDomain] {
    ///         [.avatars, .searchResults]
    ///     }
    /// }
    /// ```
    ///
    /// - SeeAlso: ``CacheDomain``
    protocol CacheDomainListDelegate {
        /// The cache domains defined by the host app.
        var appCacheDomains: [CacheDomain] { get }
    }

    /// The default delegate, which returns only the subsystem's
    /// built-in cache domains.
    struct DefaultCacheDomainListDelegate: CacheDomainListDelegate {
        public let appCacheDomains = CacheDomain.subsystemCases
    }
}
