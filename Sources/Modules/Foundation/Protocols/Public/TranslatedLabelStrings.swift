//
//  TranslatedLabelStrings.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A type that declares the set of translatable strings for a view or
/// component.
///
/// Conform to `TranslatedLabelStrings` to define a collection of
/// translation key pairs that map each label string to its
/// ``TranslationInputMap``. The subsystem uses these pairs to
/// translate the strings at runtime and produce a corresponding array
/// of ``TranslationOutputMap`` values.
///
/// A typical conformance enumerates the view's string keys and maps
/// each case to a ``TranslationInputMap``:
///
/// ```swift
/// enum ProfileViewStrings: TranslatedLabelStrings {
///     static var keyPairs: [TranslationInputMap] {
///         TranslatedLabelStringCollection.ProfileViewStringKey.allCases
///             .map {
///                 TranslationInputMap(
///                     key: .profileView($0),
///                     input: .init($0.rawValue, alternate: $0.alternate)
///                 )
///             }
///     }
/// }
/// ```
///
/// - SeeAlso: ``TranslatedLabelStringKey``,
///   ``TranslationInputMap``, ``TranslationOutputMap``
public protocol TranslatedLabelStrings {
    /// The translation key pairs for this collection.
    ///
    /// Each entry pairs a ``TranslatedLabelStringCollection`` key
    /// with a `TranslationInput` that provides the original string
    /// and an optional alternate translation.
    static var keyPairs: [TranslationInputMap] { get }
}

/// A type that represents an individual translatable string key.
///
/// Conform to `TranslatedLabelStringKey` to define string keys that
/// may provide an alternate translation value. The ``alternate``
/// property returns a substitute string when the default translation
/// is not appropriate for a given context.
///
/// - SeeAlso: ``TranslatedLabelStrings``
public protocol TranslatedLabelStringKey {
    /// An alternate string to use in place of the default
    /// translation, or `nil` if no alternate is needed.
    var alternate: String? { get }
}

public extension TranslatedLabelStrings {
    /// The default output map derived from this collection's key
    /// pairs.
    ///
    /// Each entry resolves to the original English string when the
    /// active language code is `"en"`, or to the stored translation
    /// value otherwise. Use this property as a fallback when
    /// translation results are not yet available or fail to resolve.
    static var defaultOutputMap: [TranslationOutputMap] {
        keyPairs.map(\.defaultOutputMap)
    }
}
