//
//  CacheDomain.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A named group of cached entries that can be cleared as a unit.
///
/// A `CacheDomain` pairs a string identifier with a closure that
/// removes all cached entries belonging to that domain. The subsystem
/// uses cache domains to offer granular "clear caches" controls in
/// Developer Mode and during memory-pressure cleanup.
///
/// ## Defining a Cache Domain
///
/// Create a static property on `CacheDomain` for each logical group
/// of cached data in your app:
///
/// ```swift
/// extension CacheDomain {
///     static let avatars: CacheDomain = .init("avatars") {
///         AvatarCache.shared.clear()
///     }
/// }
/// ```
///
/// Then register your domains through the
/// ``AppSubsystem/Delegates/CacheDomainListDelegate`` so they appear
/// in ``allCases``.
///
/// Two cache domains are considered equal when their ``rawValue``
/// strings match; the ``clear`` closure is not compared.
///
/// - SeeAlso: ``Cached``, ``Cacheable``,
///   ``AppSubsystem/Delegates/CacheDomainListDelegate``
public struct CacheDomain: CaseIterable, Hashable, Sendable {
    // MARK: - Properties

    let clear: @Sendable () -> Void
    let rawValue: String

    // MARK: - Computed Properties

    /// Every registered cache domain, combining both app and
    /// subsystem domains.
    public static var allCases: [CacheDomain] {
        (AppSubsystem.delegates.cacheDomainList.appCacheDomains + CacheDomain.subsystemCases).unique
    }

    // MARK: - Init

    /// Creates a cache domain with the given identifier and clear
    /// action.
    ///
    /// - Parameters:
    ///   - rawValue: A string that uniquely identifies the domain.
    ///   - clear: A closure that removes all cached entries belonging
    ///     to this domain.
    public init(
        _ rawValue: String,
        clear: @escaping @Sendable () -> Void
    ) {
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
