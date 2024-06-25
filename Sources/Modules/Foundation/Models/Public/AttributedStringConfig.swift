//
//  AttributedStringConfig.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/* Proprietary */
import AlertKit

public struct AttributedStringConfig {
    // MARK: - Types

    public struct StringAttributes {
        /* MARK: Properties */

        public let attributes: [NSAttributedString.Key: Any]
        public let stringRanges: [String]

        /* MARK: Init */

        public init(
            _ attributes: [NSAttributedString.Key: Any],
            stringRanges: [String]
        ) {
            assert(!attributes.isEmpty && !stringRanges.isEmpty, "Instantiated StringAttributes with empty attributes or stringRanges array")
            self.attributes = attributes
            self.stringRanges = stringRanges.filter { !$0.isEmpty }.unique
        }
    }

    // MARK: - Properties

    public let primaryAttributes: [NSAttributedString.Key: Any]
    public let secondaryAttributes: [StringAttributes]?

    // MARK: - Computed Properties

    public var alertKitMapping: AlertKit.AttributedStringConfig {
        .init(
            primaryAttributes,
            secondaryAttributes: secondaryAttributes?
                .compactMap { AlertKit.AttributedStringConfig.StringAttributes(
                    $0.attributes,
                    stringRanges: $0.stringRanges
                ) }
        )
    }

    // MARK: - Init

    public init(
        _ primaryAttributes: [NSAttributedString.Key: Any],
        secondaryAttributes: [StringAttributes]? = nil
    ) {
        assert(!primaryAttributes.isEmpty, "Instantiated AttributedStringConfig with empty primaryAttributes dictionary")
        self.primaryAttributes = primaryAttributes
        self.secondaryAttributes = secondaryAttributes
    }
}
