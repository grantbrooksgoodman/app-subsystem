//
//  Localized.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A property wrapper that resolves a localized string from a
/// property list at access time.
///
/// Use `@Localized` to declare a string property whose value is
/// resolved from a ``LocalizationSource`` by key and language
/// code:
///
/// ```swift
/// @Localized(key: .helloWorld, source: .app())
/// var greeting: String
/// ```
///
/// The source determines which property list and bundle the
/// wrapper reads from. Define a constrained extension on
/// `Localized` to provide a default source for your key type:
///
/// ```swift
/// extension Localized where T == StringKey {
///     init(
///         _ key: StringKey,
///         languageCode: String = RuntimeStorage.languageCode,
///         source: LocalizationSource = .app()
///     ) {
///         self.init(
///             key: key,
///             languageCode: languageCode,
///             source: source
///         )
///     }
/// }
/// ```
///
/// With this extension in place:
///
///     @Localized(.helloWorld) var greeting: String
///
/// ## Property List Structure
///
/// The property list for a given source is a dictionary of
/// dictionaries. Each top-level key corresponds to a
/// localization key's ``referent`` value, and its nested
/// dictionary maps language codes to translated strings:
///
/// ```xml
/// <dict>
///     <key>greeting</key>
///     <dict>
///         <key>en</key>
///         <string>Hello</string>
///         <key>es</key>
///         <string>Hola</string>
///         ...
///     </dict>
/// </dict>
/// ```
///
/// The lookup is backed by an internal cache, so repeated
/// accesses do not re-read the property list from disk.
///
/// - Note: If no translation is found for the requested
///   language, English is used as a fallback. If the English
///   translation is also missing, the wrapper returns `"�"`.
///
/// - SeeAlso: ``LocalizationSource``,
///   ``LocalizedStringKeyRepresentable``
@propertyWrapper
public struct Localized<T: LocalizedStringKeyRepresentable>: Equatable {
    // MARK: - Properties

    private let key: T
    private let languageCode: String
    private let source: LocalizationSource

    // MARK: - Init

    /// Creates a localized string wrapper for the given key,
    /// language code, and source.
    ///
    /// - Parameters:
    ///   - key: The localization key to look up.
    ///   - languageCode: The language to resolve the string for.
    ///     Defaults to ``RuntimeStorage/languageCode``.
    ///   - source: The property list and bundle to read from.
    public init(
        key: T,
        languageCode: String = RuntimeStorage.languageCode,
        source: LocalizationSource
    ) {
        self.key = key
        self.languageCode = languageCode
        self.source = source
    }

    init(_ key: T) {
        self.init(
            key: key,
            source: .subsystem
        )
    }

    // MARK: - WrappedValue

    /// The localized string for the specified key and language code.
    public var wrappedValue: String {
        LocalizedStringResolver.string(
            for: key,
            language: languageCode,
            source: source
        )
    }
}
