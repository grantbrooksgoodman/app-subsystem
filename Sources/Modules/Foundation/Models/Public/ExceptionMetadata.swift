//
//  ExceptionMetadata.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A convenience alias for ``Exception/Metadata``.
public typealias ExceptionMetadata = Exception.Metadata

public extension Exception {
    /// Source-location information captured at the point where an
    /// ``Exception`` is created.
    ///
    /// `Metadata` records the file, function, line, and sender so
    /// that logged exceptions can be traced back to their origin. The
    /// compiler literals `#fileID`, `#function`, and `#line` are
    /// captured automatically – you only need to supply the `sender`:
    ///
    /// ```swift
    /// Exception(
    ///     "Something went wrong.",
    ///     metadata: .init(sender: self)
    /// )
    /// ```
    ///
    /// ## Identifiers
    ///
    /// The ``id`` property produces a compact hex string derived from
    /// the file name and line number, suitable for use in log output
    /// and diagnostics.
    ///
    /// - SeeAlso: ``Exception``, ``MetadataProtocol``
    struct Metadata: MetadataProtocol, @unchecked Sendable {
        // MARK: - Properties

        /// The object or type that created the exception.
        ///
        /// - Important: This property is exposed for use by the
        ///   subsystem's logging infrastructure. Don't read or
        ///   rely on it in your own code.
        public let sender: Any

        let fileName: String
        let function: String
        let line: Int

        // MARK: - Computed Properties

        var id: String {
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

        /// Creates metadata for the current source location.
        ///
        /// The `fileName`, `function`, and `line` parameters default
        /// to their corresponding compiler literals. In most cases,
        /// you only need to supply the `sender`.
        ///
        /// - Parameters:
        ///   - sender: The object or type creating the exception.
        ///   - fileName: The source file name. Defaults to `#fileID`.
        ///   - function: The function name. Defaults to `#function`.
        ///   - line: The line number. Defaults to `#line`.
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
