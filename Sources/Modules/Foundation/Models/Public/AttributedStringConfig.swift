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

/// A configuration that describes how to style a string by applying a
/// set of primary attributes to the entire text and optional secondary
/// attributes to specific substrings.
///
/// Use `AttributedStringConfig` when you need to pass rich-text styling
/// through a subsystem API that ultimately builds an
/// `NSAttributedString`:
///
/// ```swift
/// let config = AttributedStringConfig(
///     [.font: UIFont.boldSystemFont(ofSize: 16)],
///     secondaryAttributes: [
///         .init(
///             [.foregroundColor: UIColor.red],
///             stringRanges: ["important"]
///         ),
///     ]
/// )
/// ```
///
/// The ``primaryAttributes`` are applied to the full string first.
/// Each entry in ``secondaryAttributes`` is then applied to every
/// occurrence of its ``StringAttributes/stringRanges`` within the
/// text, allowing you to highlight or restyle specific words or
/// phrases.
///
/// - SeeAlso: ``StringAttributes``
public struct AttributedStringConfig {
    // MARK: - Types

    /// A pairing of `NSAttributedString` attributes with the
    /// substrings they should be applied to.
    ///
    /// Each `StringAttributes` instance targets one or more substrings
    /// within the parent text. The attributes are applied to every
    /// occurrence of each string range.
    public struct StringAttributes {
        /* MARK: Properties */

        let attributes: [NSAttributedString.Key: Any]
        let stringRanges: [String]

        /* MARK: Init */

        /// Creates a string-attributes pairing.
        ///
        /// Empty string ranges are filtered out, and duplicates are
        /// removed.
        ///
        /// - Parameters:
        ///   - attributes: The `NSAttributedString` attributes to
        ///     apply. Must not be empty.
        ///   - stringRanges: The substrings to target. Must not be
        ///     empty.
        public init(
            _ attributes: [NSAttributedString.Key: Any],
            stringRanges: [String]
        ) {
            assert(
                !attributes.isEmpty && !stringRanges.isEmpty,
                "Instantiated StringAttributes with empty attributes or stringRanges array"
            )

            self.attributes = attributes
            self.stringRanges = stringRanges.filter { !$0.isEmpty }.unique
        }
    }

    // MARK: - Properties

    let primaryAttributes: [NSAttributedString.Key: Any]
    let secondaryAttributes: [StringAttributes]?

    // MARK: - Computed Properties

    var alertKitMapping: AlertKit.AttributedStringConfig {
        .init(
            primaryAttributes,
            secondaryAttributes: secondaryAttributes?
                .compactMap {
                    AlertKit.AttributedStringConfig.StringAttributes(
                        $0.attributes,
                        stringRanges: $0.stringRanges
                    )
                }
        )
    }

    // MARK: - Init

    /// Creates an attributed string configuration.
    ///
    /// - Parameters:
    ///   - primaryAttributes: The attributes applied to the full
    ///     string. Must not be empty.
    ///   - secondaryAttributes: Optional attribute sets for specific
    ///     substrings.
    public init(
        _ primaryAttributes: [NSAttributedString.Key: Any],
        secondaryAttributes: [StringAttributes]? = nil
    ) {
        assert(
            !primaryAttributes.isEmpty,
            "Instantiated AttributedStringConfig with empty primaryAttributes dictionary"
        )

        self.primaryAttributes = primaryAttributes
        self.secondaryAttributes = secondaryAttributes
    }
}
