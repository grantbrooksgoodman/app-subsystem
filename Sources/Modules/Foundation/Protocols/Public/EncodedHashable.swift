//
//  EncodedHashable.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

// swiftlint:disable identifier_name

/* Native */
import CryptoKit
import Foundation

/// A type that can produce a deterministic, SHA-256-based identifier
/// from an array of string factors.
///
/// Conform to `EncodedHashable` to give a type a stable, content-derived
/// identifier that is suitable for equality checks, persistent storage
/// keys, or cache lookups. The protocol requires a single property,
/// ``hashFactors``, which supplies the strings that feed into the
/// hash computation:
///
/// ```swift
/// struct Document: EncodedHashable {
///     let title: String
///     let version: Int
///
///     var hashFactors: [String] {
///         [title, String(version)]
///     }
/// }
/// ```
///
/// The default implementation of ``encodedHash`` JSON-encodes the
/// factors, computes a SHA-256 digest, and returns the result as a
/// lowercase hexadecimal string. Computed hashes are cached in memory,
/// so repeated access for the same factors is inexpensive.
///
/// `String` conforms to `EncodedHashable` out of the box, making it
/// easy to obtain a hash for any string value.
///
/// - Note: Because the hash is derived from the content of
///   ``hashFactors``, two instances with the same factors always
///   produce the same ``encodedHash``, regardless of type.
public protocol EncodedHashable {
    /// The strings that collectively define this instance's identity
    /// for hashing purposes.
    ///
    /// The order and content of the returned array directly affect the
    /// resulting ``encodedHash``. Changing the factors – or their
    /// order – produces a different hash.
    var hashFactors: [String] { get }
}

public extension EncodedHashable {
    /// A deterministic, SHA-256-based hexadecimal string derived from
    /// ``hashFactors``.
    ///
    /// The factors are JSON-encoded and then hashed using SHA-256.
    /// The result is a 64-character lowercase hexadecimal string.
    /// Computed hashes are cached in memory for the lifetime of the
    /// process, so accessing this property repeatedly for the same
    /// factors does not recompute the digest.
    var encodedHash: String {
        @Dependency(\.jsonEncoder) var jsonEncoder: JSONEncoder
        let compiledString = hashFactors.joined()

        if let storedValue = EncodedHashStore.storedEncodedHashesForCompiledHashFactorStrings.projectedValue[compiledString] {
            return storedValue
        }

        do {
            let encodedHash = try jsonEncoder.encode(hashFactors).encodedHash
            EncodedHashStore.storedEncodedHashesForCompiledHashFactorStrings.projectedValue[compiledString] = encodedHash
            return encodedHash
        } catch {
            Logger.log(.init(error, metadata: .init(sender: self)))
            return Data().encodedHash
        }
    }
}

enum EncodedHashStore {
    // MARK: - Properties

    static let storedEncodedHashesForCompiledHashFactorStrings = LockIsolated([String: String]())

    // MARK: - Clear Cache

    static func clearStore() {
        storedEncodedHashesForCompiledHashFactorStrings.wrappedValue = [:]
    }
}

private extension Data {
    var encodedHash: String {
        SHA256.hash(data: self).compactMap { String(format: "%02x", $0) }.joined()
    }
}

// swiftlint:enable identifier_name
