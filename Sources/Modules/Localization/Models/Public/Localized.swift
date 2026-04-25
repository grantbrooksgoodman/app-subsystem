//
//  Localized.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A property wrapper that resolves a localized string from the
/// app's `LocalizedStrings.plist` file.
///
/// Use `@Localized` to declare a string property whose value is looked up
/// at access time for a given key and language:
///
/// ```swift
/// @Localized(.hello, languageCode: "es")
/// var greeting: String    // greeting == "Hola"
/// ```
///
/// The lookup is backed by an internal cache, so repeated accesses do not
/// re-read the property list from disk.
///
/// ## Property List Structure
///
/// `LocalizedStrings.plist` is a dictionary of dictionaries. Each
/// top-level key corresponds to a ``LocalizedStringKeyRepresentable``
/// referent, and its value is a dictionary mapping language codes to
/// translated strings:
///
/// ```xml
/// <dict>
///     <key>greeting</key>
///     <dict>
///         <key>en</key>
///         <string>Hello</string>
///         <key>es</key>
///         <string>Hola</string>
///     </dict>
/// </dict>
/// ```
///
/// - Note: If no translation is found for the requested language, English is used
/// as a fallback. If the English translation is also missing, the wrapper
/// returns `"�"`.
///
/// - SeeAlso: ``LocalizedStringKeyRepresentable``
@propertyWrapper
public struct Localized<T: LocalizedStringKeyRepresentable>: Equatable {
    // MARK: - Properties

    private let key: T
    private let languageCode: String

    // MARK: - Init

    /// Creates a localized string wrapper for the given key and language code.
    ///
    /// - Parameters:
    ///   - key: The localization key to look up.
    ///   - languageCode: The language to resolve the string for.
    ///     Defaults to ``RuntimeStorage/languageCode``.
    public init(
        _ key: T,
        languageCode: String = RuntimeStorage.languageCode
    ) {
        self.key = key
        self.languageCode = languageCode
    }

    // MARK: - WrappedValue

    /// The localized string for the configured key and language code.
    public var wrappedValue: String {
        Localization.string(
            for: key,
            language: languageCode
        )
    }
}
