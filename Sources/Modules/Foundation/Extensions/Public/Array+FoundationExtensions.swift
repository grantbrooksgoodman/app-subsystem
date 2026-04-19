//
//  Array+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension Array {
    /// Convenience method eliminating the need to guard against out of bounds errors.
    func itemAt(_ index: Int) -> Element? {
        guard index > -1, count > index else { return nil }
        return self[index]
    }
}

public extension [Exception] {
    // MARK: - Properties

    /// Returns a single ``Exception`` by appending each as
    /// an underlying ``Exception`` to the final item in the array.
    var compiledException: Exception? {
        guard !isEmpty else { return nil }
        var finalException = last!
        guard count > 1 else { return finalException }
        Array(reversed()[1 ... count - 1]).unique.forEach { finalException = finalException.appending(underlyingException: $0) }
        return finalException
    }

    // TODO: Audit this – consider removing/replacing.
    /// An array of reference-code strings derived from each
    /// exception and its underlying exceptions.
    var referenceCodes: [String] {
        var codes = [String]()

        for (index, exception) in enumerated() {
            let suffix = codes.contains(where: { $0.hasPrefix(exception.code.lowercased()) }) ? "x\(index)" : ""
            codes.append("\(exception.code)x\(exception.metadata.id)\(suffix)".lowercased())

            if let underlyingExceptions = exception.underlyingExceptions {
                for (index, underlyingException) in underlyingExceptions.enumerated() {
                    let suffix = codes.contains(where: { $0.hasPrefix(underlyingException.code.lowercased()) }) ? "x\(index)" : ""
                    codes.append("\(underlyingException.code)x\(underlyingException.metadata.id)\(suffix)".lowercased())
                }
            }
        }

        return codes
    }
}

public extension [String] {
    // MARK: - Properties

    /// The duplicate strings in the array, or `nil` if none exist.
    var duplicates: [String]? {
        let duplicates = Array(Set(filter { (string: String) in filter { $0 == string }.count > 1 }))
        return duplicates.isEmpty ? nil : duplicates
    }

    // MARK: - Methods

    /// Returns `true` if the array contains at least one string
    /// from the given array.
    func containsAnyString(in array: [String]) -> Bool {
        !array.filter { contains($0) }.isEmpty
    }

    /// Returns `true` if the array contains every string in the
    /// given array.
    func containsAllStrings(in array: [String]) -> Bool {
        array.allSatisfy(contains)
    }

    /// Returns the number of elements equal to the given string.
    func count(of query: String) -> Int {
        reduce(into: Int()) { partialResult, string in
            partialResult += string == query ? 1 : 0
        }
    }
}
