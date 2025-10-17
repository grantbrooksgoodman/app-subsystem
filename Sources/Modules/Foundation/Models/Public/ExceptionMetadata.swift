//
//  ExceptionMetadata.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public typealias ExceptionMetadata = Exception.Metadata

public extension Exception {
    struct Metadata: MetadataProtocol {
        // MARK: - Properties

        public let fileName: String
        public let function: String
        public let line: Int
        public let sender: Any

        // MARK: - Computed Properties

        public var id: String {
            var hexCharacters = fileName
                .compactMap(\.asciiValue)
                .reduce(into: [String]()) { partialResult, asciiValue in
                    partialResult.append(String(format: "%02X", asciiValue))
                }

            if hexCharacters.count > 3 {
                var subsequence = Array(hexCharacters[0 ... 3])
                subsequence.append(hexCharacters.last!)
                hexCharacters = subsequence
            }

            return "\(hexCharacters.joined())x\(line)".lowercased()
        }

        // MARK: - Init

        public init(
            sender: Any,
            fileName: String = #fileID,
            function: String = #function,
            line: Int = #line
        ) {
            self.sender = sender
            self.fileName = fileName.lastPathComponent
            self.function = function
            self.line = line
        }

        // MARK: - Equatable Conformance

        public static func == (left: Self, right: Self) -> Bool {
            let sameFileName = left.fileName == right.fileName
            let sameFunction = left.function == right.function
            let sameLine = left.line == right.line
            let sameSender = String(left.sender) == String(right.sender)

            guard sameFileName,
                  sameFunction,
                  sameLine,
                  sameSender else { return false }

            return true
        }

        // MARK: - Hashable Conformance

        public func hash(into hasher: inout Hasher) {
            hasher.combine(String(sender))
            hasher.combine(fileName)
            hasher.combine(function)
            hasher.combine(line)
        }
    }
}

private extension String {
    // TODO: Audit the "?? self".
    var lastPathComponent: String {
        components(separatedBy: "/")
            .last?
            .components(separatedBy: ".")
            .first ?? self
    }
}
