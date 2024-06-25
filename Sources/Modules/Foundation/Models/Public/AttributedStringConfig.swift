//
//  AttributedStringConfig.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public struct AttributedStringConfig {
    // MARK: - Properties

    public let attributes: [NSAttributedString.Key: Any]
    public let stringRanges: [String]

    // MARK: - Init

    public init(
        _ attributes: [NSAttributedString.Key: Any],
        stringRanges: [String]
    ) {
        assert(!attributes.isEmpty && !stringRanges.isEmpty, "Instantiated AttributedStringConfig with empty attributes or stringRanges array")
        self.attributes = attributes
        self.stringRanges = stringRanges.filter { !$0.isEmpty }.unique
    }
}
