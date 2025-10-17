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

        if let storedValue = EncodedHashStore.storedEncodedHashesForCompiledHashFactorStrings[compiledString] {
            return storedValue
        }

        do {
            let encodedHash = try jsonEncoder.encode(hashFactors).encodedHash
            EncodedHashStore.storedEncodedHashesForCompiledHashFactorStrings[compiledString] = encodedHash
            return encodedHash
        } catch {
            Logger.log(.init(error, metadata: .init(sender: self)))
            return Data().encodedHash
        }
    }
}

enum EncodedHashStore {
    // MARK: - Properties

    @LockIsolated static var storedEncodedHashesForCompiledHashFactorStrings = [String: String]()

    // MARK: - Clear Cache

    static func clearStore() {
        storedEncodedHashesForCompiledHashFactorStrings = .init()
    }
}

private extension Data {
    var encodedHash: String {
        SHA256.hash(data: self).compactMap { String(format: "%02x", $0) }.joined()
    }
}

// swiftlint:enable identifier_name
