//
//  TranslatedLabelStringCollection.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A strongly typed key that identifies a translatable label string
/// within a view or component.
///
/// Define keys for each view as static type methods in an
/// extension, mapping a view-specific
/// ``TranslatedLabelStringKey`` enumeration to a collection key:
///
/// ```swift
/// extension TranslatedLabelStringCollection {
///     static func profileView(
///         _ key: ProfileViewStringKey
///     ) -> TranslatedLabelStringCollection {
///         .init(key.rawValue)
///     }
/// }
/// ```
///
/// These keys are used by ``TranslationInputMap`` and
/// ``TranslationOutputMap`` to pair each translatable string with
/// its translated value.
///
/// - SeeAlso: ``TranslatedLabelStrings``,
///   ``TranslatedLabelStringKey``
public struct TranslatedLabelStringCollection: Hashable, Sendable {
    // MARK: - Properties

    let rawValue: String

    // MARK: - Init

    /// Creates a label string collection key with the given
    /// identifier.
    ///
    /// - Parameter rawValue: A string that uniquely names the
    ///   translatable label.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}
