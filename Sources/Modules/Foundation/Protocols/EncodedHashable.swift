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

public protocol EncodedHashable {
    var hashFactors: [String] { get }
}

public extension EncodedHashable {
    var encodedHash: String {
        @Dependency(\.jsonEncoder) var jsonEncoder: JSONEncoder
        let compiledString = hashFactors.reduce(String(), +)

        if let cachedValue = _EncodedHashCache.cachedEncodedHashesForCompiledHashFactorStrings[compiledString] {
            return cachedValue
        }

        do {
            let encodedHash = try jsonEncoder.encode(hashFactors).encodedHash

//            var cachedEncodedHashesForCompiledHashFactorStrings = _EncodedHashCache.shared.cachedEncodedHashesForCompiledHashFactorStrings ?? [:]
//            cachedEncodedHashesForCompiledHashFactorStrings[compiledString] = encodedHash
            _EncodedHashCache.cachedEncodedHashesForCompiledHashFactorStrings[compiledString] = encodedHash
//            _EncodedHashCache.shared.cachedEncodedHashesForCompiledHashFactorStrings = cachedEncodedHashesForCompiledHashFactorStrings

            return encodedHash
        } catch {
            Logger.log(.init(error, metadata: [self, #file, #function, #line]))
            return Data().encodedHash
        }
    }
}

private extension Data {
    var encodedHash: String {
        SHA256.hash(data: self).compactMap { String(format: "%02x", $0) }.joined()
    }
}

public enum EncodedHashCache {
    public static func clearCache() {
        _EncodedHashCache.clearCache()
    }
}

private enum _EncodedHashCache {
    // MARK: - Types

    private enum CacheKey: String, CaseIterable {
        case encodedHashesForCompiledHashFactorStrings
    }

    // MARK: - Properties

//    public static let shared = _EncodedHashCache()

    /*@Cached(CacheKey.encodedHashesForCompiledHashFactorStrings)*/
    @LockIsolated public static var cachedEncodedHashesForCompiledHashFactorStrings = [String: String]()

    // MARK: - Init

//    private init() {}

    // MARK: - Clear Cache

    public static func clearCache() {
        cachedEncodedHashesForCompiledHashFactorStrings = .init()
    }
}

// swiftlint:enable identifier_name
