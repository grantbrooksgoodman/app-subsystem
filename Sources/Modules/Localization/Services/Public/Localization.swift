//
//  Localization.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/* Proprietary */
import Translator

/// A type that translates strings into supported languages
/// and writes the results to a localized strings property
/// list.
///
/// Use `Localization` to populate a localized strings
/// property list during development. The
/// ``createPLIST(translating:sourceLanguageCode:plistConfig:postProcessingConfig:translate:)``
/// method translates the input string into every language
/// in the app's language code dictionary and writes the
/// results to a property list in the app's temporary
/// directory. If a property list with the specified name
/// exists in the configured bundle, its entries are
/// preserved in the output.
///
/// The following example translates "Hello, world!" and
/// stores the results under the key `greeting`:
///
/// ```swift
/// let createPLISTResult = await Localization.createPLIST(
///     translating: "Hello, world!",
///     plistConfig: .init(key: "greeting")
/// )
///
/// switch createPLISTResult {
/// case let .success(filePath):
///     Logger.log("Written to \(filePath)", sender: self)
/// case let .failure(exception):
///     Logger.log(exception)
/// }
/// ```
///
/// - SeeAlso: ``Localized``, ``LocalizationSource``,
///   ``LocalizedStringKeyRepresentable``
public enum Localization {
    // MARK: - Types

    /// A configuration that controls how translated strings
    /// are processed before they are written to the property
    /// list.
    ///
    /// Use `PostProcessingConfiguration` to apply
    /// capitalization rules, character stripping, or string
    /// replacements to each translated output. All
    /// translations are stripped of translation sentinel characters
    /// and trimmed of leading and trailing whitespace regardless
    /// of whether a post-processing configuration is provided.
    ///
    /// When a configuration is provided, operations are
    /// applied in the following order:
    ///
    /// 1. Capitalization
    /// 2. Sentinel replacement
    /// 3. Character stripping
    public struct PostProcessingConfiguration: Sendable {
        /* MARK: Properties */

        fileprivate let capitalizationLengthThreshold: Int?
        fileprivate let sentinelReplacements: [String: String]?
        fileprivate let strippingCharacterSet: CharacterSet?

        /* MARK: Init */

        /// Creates a post-processing configuration.
        ///
        /// - Parameters:
        ///   - capitalizationLengthThreshold: The minimum
        ///     character count a word must exceed to have its
        ///     first character capitalized. The first and
        ///     last words are always capitalized regardless
        ///     of length. Pass `nil` to skip capitalization.
        ///   - sentinelReplacements: A dictionary of strings
        ///     to find and their replacements. Each key
        ///     found in a translated output is replaced with
        ///     its corresponding value. Pass `nil` to skip
        ///     replacement.
        ///   - strippingCharacterSet: A set of characters to
        ///     strip from each word of the translated
        ///     output. Pass `nil` to skip character
        ///     stripping.
        ///
        /// - Warning: At least one parameter must be non-`nil`.
        /// Passing `nil` for all three triggers a runtime assertion
        /// failure.
        public init(
            capitalizationLengthThreshold: Int? = nil,
            sentinelReplacements: [String: String]? = nil,
            strippingCharacterSet: CharacterSet? = nil
        ) {
            assert(
                capitalizationLengthThreshold != nil ||
                    sentinelReplacements != nil ||
                    strippingCharacterSet != nil,
                "\(Self.self) – At least one non-nil value must be provided to init"
            )

            self.capitalizationLengthThreshold = capitalizationLengthThreshold
            self.sentinelReplacements = sentinelReplacements
            self.strippingCharacterSet = strippingCharacterSet
        }
    }

    /// A configuration for the property list that
    /// ``Localization`` generates when resolving strings.
    ///
    /// A `PropertyListConfiguration` specifies the dictionary key under
    /// which translated strings are stored and the name of
    /// the output property list. When a property list with
    /// the specified name exists in the configured bundle,
    /// its entries are preserved in the output. By default,
    /// the configuration uses the name `LocalizedStrings`,
    /// searches the main bundle, and overwrites any
    /// existing output file.
    ///
    /// The following example stores translations under the
    /// key `welcome_message` in a property list named
    /// `AppStrings`:
    ///
    /// ```swift
    /// let config = Localization.PropertyListConfiguration(
    ///     key: "welcome_message",
    ///     name: "AppStrings"
    /// )
    /// ```
    public struct PropertyListConfiguration: Sendable {
        /* MARK: Properties */

        fileprivate let bundle: Bundle
        fileprivate let key: String
        fileprivate let name: String
        fileprivate let overwriteExistingFile: Bool

        /* MARK: Init */

        /// Creates a property list configuration.
        ///
        /// - Parameters:
        ///   - bundle: The bundle to search for an existing
        ///     property list whose entries are preserved in
        ///     the output. Defaults to the main bundle.
        ///   - key: The top-level dictionary key under which
        ///     translations are stored in the property list.
        ///   - name: The name of the property list file,
        ///     without the `.plist` extension. Defaults to
        ///     `"LocalizedStrings"`.
        ///   - overwriteExistingFile: A Boolean value that
        ///     determines whether an existing file at the
        ///     output path is replaced. When `false`, the
        ///     operation returns a failure if a file already
        ///     exists at the output path. Defaults to `true`.
        public init(
            bundle: Bundle = .main,
            key: String,
            name: String = "LocalizedStrings",
            overwriteExistingFile: Bool = true
        ) {
            self.bundle = bundle
            self.key = key
            self.name = name
            self.overwriteExistingFile = overwriteExistingFile
        }
    }

    // MARK: - Create PLIST

    /// Translates a string into all supported languages and
    /// writes the results to a property list.
    ///
    /// This method translates `input` into every language
    /// in the app's language code dictionary and writes the
    /// results to a property list in the app's temporary
    /// directory. If a property list with the name
    /// specified by `plistConfig` exists in the configured
    /// bundle, its entries are preserved in the output.
    ///
    /// The method uses the ``TranslationService``
    /// dependency to perform translations by default. To
    /// provide a custom implementation, pass a closure to
    /// the `translate` parameter. The closure receives the
    /// target language code and returns a ``Callback`` with
    /// a `Translation` on success or an ``Exception`` on
    /// failure.
    ///
    /// - Parameters:
    ///   - input: The string to translate.
    ///   - languageCode: The language of the input string.
    ///     Defaults to `"en"`.
    ///   - plistConfig: The configuration that specifies the
    ///     output file name, bundle, dictionary key, and
    ///     overwrite behavior.
    ///   - postProcessingConfig: A configuration that
    ///     controls how translated strings are processed
    ///     before they are written to the property list, or
    ///     `nil` to apply default sanitization and
    ///     whitespace trimming only.
    ///   - translate: A closure that translates the input
    ///     string into a target language, or `nil` to use
    ///     the default translation service.
    ///
    /// - Returns: A ``Callback`` containing the file path
    ///   of the generated property list on success, or an
    ///   ``Exception`` on failure.
    public static func createPLIST(
        translating input: String,
        sourceLanguageCode languageCode: String = "en",
        plistConfig: PropertyListConfiguration,
        postProcessingConfig: PostProcessingConfiguration? = nil,
        translate: ((String) async -> Callback<Translation, Exception>)? = nil
    ) async -> Callback<String, Exception> {
        @Dependency(\.translationService) var translator: TranslationService

        guard let languageCodes = RuntimeStorage.languageCodeDictionary?.keys else {
            return .failure(.init(
                "Failed to resolve language codes.",
                metadata: .init(sender: self)
            ))
        }

        var propertyList = [String: [String: String]]()
        if let plistURL = plistConfig
            .bundle
            .url(
                forResource: plistConfig.name,
                withExtension: "plist"
            ),
            let plistData = try? Data(contentsOf: plistURL),
            let existingEntries = try? PropertyListSerialization.propertyList(
                from: plistData,
                format: nil
            ) as? [String: [String: String]] {
            propertyList = existingEntries
        }

        Logger.openStream(
            domain: .localization,
            sender: self
        )

        var totalCompleted = 0
        let translateResults = await languageCodes.parallelMap(
            failForEmptyCollection: true
        ) {
            totalCompleted += 1

            Logger.log(
                "Translating item \(totalCompleted) of \(languageCodes.count).",
                domain: .localization,
                sender: self
            )

            if let translate {
                return await translate($0)
            }

            return await translator.translate(
                .init(input),
                languagePair: .init(
                    from: languageCode,
                    to: $0
                )
            )
        }

        var translationOutputsByLanguageCode = [String: String]()
        switch translateResults {
        case let .success(translations):
            translationOutputsByLanguageCode = translations
                .reduce(into: [String: String]()) { partialResult, translation in
                    partialResult[translation.languagePair.to] = postProcess(
                        translation.output,
                        with: postProcessingConfig
                    )
                }

        case let .failure(exception):
            return .failure(exception)
        }

        Logger.closeStream(
            message: "All strings should be translated; complete.",
            domain: .localization,
            onLine: #line
        )

        propertyList[plistConfig.key] = translationOutputsByLanguageCode
        return createPLIST(
            from: propertyList,
            fileName: plistConfig.name,
            overwriteExistingFile: plistConfig.overwriteExistingFile
        )
    }

    // MARK: - Auxiliary

    private static func postProcess(
        _ string: String,
        with configuration: PostProcessingConfiguration?
    ) -> String {
        guard let configuration else { return string.sanitized.trimmingBorderedWhitespace }
        let whitespaceSeparatedComponents = string
            .sanitized
            .trimmingBorderedWhitespace
            .components(separatedBy: .whitespaces)

        var stringComponents = [String]()
        if let lengthThreshold = configuration.capitalizationLengthThreshold {
            for (index, component) in whitespaceSeparatedComponents.enumerated() {
                guard component.count > lengthThreshold ||
                    index == 0 ||
                    index == whitespaceSeparatedComponents.count - 1 else {
                    stringComponents.append(component)
                    continue
                }

                stringComponents.append(component.firstUppercase)
            }
        } else {
            stringComponents = whitespaceSeparatedComponents
        }

        if let sentinelReplacements = configuration.sentinelReplacements,
           !sentinelReplacements.isEmpty {
            for (key, value) in sentinelReplacements {
                stringComponents = stringComponents.map {
                    $0.replacingOccurrences(
                        of: key,
                        with: value
                    )
                }
            }
        }

        if let characterSet = configuration.strippingCharacterSet {
            stringComponents = stringComponents.map {
                $0.trimmingCharacters(in: characterSet)
            }
        }

        return stringComponents.joined(separator: " ")
    }

    private static func createPLIST(
        from dictionary: [String: [String: String]],
        fileName: String,
        overwriteExistingFile: Bool
    ) -> Callback<String, Exception> {
        @Dependency(\.fileManager) var fileManager: FileManager

        let filePathURL = URL.temporaryDirectory.appending(path: "/\(fileName).plist")
        let filePathString = filePathURL.path()

        if !overwriteExistingFile {
            guard !fileManager.fileExists(atPath: filePathString) else {
                return .failure(.init(
                    "File already exists.",
                    userInfo: ["FilePath": filePathString],
                    metadata: .init(sender: self)
                ))
            }
        } else if fileManager.fileExists(atPath: filePathString) {
            do {
                try fileManager.removeItem(at: filePathURL)
            } catch {
                return .failure(.init(
                    error,
                    userInfo: ["FilePath": filePathString],
                    metadata: .init(sender: self)
                ))
            }
        }

        NSData(
            data: Data()
        ).write(
            toFile: filePathString,
            atomically: true
        )

        NSDictionary(
            dictionary: dictionary
        ).write(
            toFile: filePathString,
            atomically: true
        )

        return .success(filePathString)
    }
}
