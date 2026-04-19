//
//  LoggerDomain.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A named category that groups related log output.
///
/// Logger domains partition log messages into logical channels so that
/// you can subscribe to only the output you care about. Define
/// app-specific domains as static properties in an extension:
///
/// ```swift
/// extension LoggerDomain {
///     static let networking: LoggerDomain = .init("networking")
///     static let persistence: LoggerDomain = .init("persistence")
/// }
/// ```
///
/// The subsystem provides several built-in domains – including
/// ``general``, ``alertKit``, ``caches``, ``observer``, and
/// ``translation`` – that cover its own internal logging. You can
/// subscribe to or unsubscribe from any domain at runtime using
/// ``Logger/subscribe(to:)`` and
/// ``Logger/unsubscribe(from:)``.
///
/// - SeeAlso: ``Logger``
public struct LoggerDomain: Hashable, Sendable {
    // MARK: - Properties

    let rawValue: String

    // MARK: - Init

    /// Creates a logger domain with the given identifier.
    ///
    /// - Parameter rawValue: A camel-case string that names the domain
    ///   (for example, `"networking"`).
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}
