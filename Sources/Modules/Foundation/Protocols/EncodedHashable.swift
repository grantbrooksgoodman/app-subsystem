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

        if let storedValue = _EncodedHashStore.storedEncodedHashesForCompiledHashFactorStrings[compiledString] {
            return storedValue
        }

        do {
            let encodedHash = try jsonEncoder.encode(hashFactors).encodedHash
            _EncodedHashStore.storedEncodedHashesForCompiledHashFactorStrings[compiledString] = encodedHash
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

public enum EncodedHashStore {
    public static func clearStore() {
        _EncodedHashStore.clearStore()
    }
}

private enum _EncodedHashStore {
    // MARK: - Properties

    @LockIsolated public static var storedEncodedHashesForCompiledHashFactorStrings = [String: String]()

    // MARK: - Clear Cache

    public static func clearStore() {
        storedEncodedHashesForCompiledHashFactorStrings = .init()
    }
}

// swiftlint:enable identifier_name
