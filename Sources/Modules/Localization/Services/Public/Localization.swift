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
/// ``createPLIST(translating:withKey:sourceLanguageCode:plistConfig:processingConfig:postProcessingTransformation:translate:)``
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
/// do {
///     let filePath = try await Localization.createPLIST(
///         translating: "Hello, world!",
///         withKey: "greeting"
///     )
///     Logger.log("Written to \(filePath)", sender: self)
/// } catch {
///     Logger.log(error)
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
    /// Use `ProcessingConfiguration` to apply
    /// capitalization rules, character stripping, or string
    /// replacements to each translated output. All
    /// translations are stripped of translation sentinel characters
    /// and trimmed of leading and trailing whitespace regardless
    /// of whether a processing configuration is provided.
    ///
    /// When a configuration is provided, operations are
    /// applied in the following order:
    ///
    /// 1. Capitalization
    /// 2. Sentinel replacement
    /// 3. Character stripping
    public struct ProcessingConfiguration: Sendable {
        /* MARK: Properties */

        fileprivate let capitalizationLengthThreshold: Int?
        fileprivate let sentinelReplacements: [String: String]?
        fileprivate let strippingCharacterSet: CharacterSet?

        /* MARK: Init */

        /// Creates a processing configuration.
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
    /// A `PropertyListConfiguration` specifies the name of
    /// the output property list and the bundle to search
    /// for existing entries. When a property list with the
    /// specified name exists in the configured bundle, its
    /// entries are preserved in the output. By default, the
    /// configuration uses the name `LocalizedStrings`,
    /// searches the main bundle, and overwrites any
    /// existing output file.
    ///
    /// The following example configures a property list
    /// named `AppStrings`:
    ///
    /// ```swift
    /// let config = Localization.PropertyListConfiguration(
    ///     name: "AppStrings"
    /// )
    /// ```
    public struct PropertyListConfiguration: Sendable {
        /* MARK: Properties */

        fileprivate let bundle: Bundle
        fileprivate let name: String
        fileprivate let overwriteExistingFile: Bool

        /* MARK: Init */

        /// Creates a property list configuration.
        ///
        /// - Parameters:
        ///   - bundle: The bundle to search for an existing
        ///     property list whose entries are preserved in
        ///     the output. Defaults to the main bundle.
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
            name: String = "LocalizedStrings",
            overwriteExistingFile: Bool = true
        ) {
            self.bundle = bundle
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
    /// target language code and returns a `Translation` on
    /// success or an ``Exception`` on failure.
    ///
    /// - Parameters:
    ///   - input: The string to translate.
    ///   - key: The top-level dictionary key under which the
    ///     translations for this input are stored in the
    ///     property list. When `nil`, the key is derived
    ///     automatically from the first three words of the
    ///     input, stripped of non-letter characters,
    ///     lowercased, and joined with underscores.
    ///   - languageCode: The language of the input string.
    ///     Defaults to `"en"`.
    ///   - plistConfig: The configuration that specifies the
    ///     output file name, bundle, and overwrite behavior.
    ///     Defaults to `.init()`.
    ///   - processingConfig: A configuration that
    ///     controls how translated strings are processed
    ///     before they are written to the property list, or
    ///     `nil` to apply default sanitization and
    ///     whitespace trimming only.
    ///   - postProcessingTransformation: A closure that
    ///     transforms each translated string after all
    ///     processing is complete, or `nil` to skip
    ///     additional transformation.
    ///   - translate: A closure that translates the input
    ///     string into a target language, or `nil` to use
    ///     the default translation service.
    ///
    /// - Returns: The file path of the generated property list.
    ///
    /// - Throws: An ``Exception``.
    public static func createPLIST(
        translating input: String,
        withKey key: String? = nil,
        sourceLanguageCode languageCode: String = "en",
        plistConfig: PropertyListConfiguration = .init(),
        processingConfig: ProcessingConfiguration? = nil,
        postProcessingTransformation postProcess: ((String) -> String)? = nil,
        translate: ((String) async throws(Exception) -> Translation)? = nil
    ) async throws(Exception) -> String {
        @Dependency(\.translationService) var translator: TranslationService

        guard let languageCodes = RuntimeStorage.languageCodeDictionary?.keys else {
            throw Exception(
                "Failed to resolve language codes.",
                metadata: .init(sender: self)
            )
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
        let translationOutputsByLanguageCode = try await languageCodes.parallelMap(
            failForEmptyCollection: true
        ) {
            totalCompleted += 1

            Logger.log(
                "Translating item \(totalCompleted) of \(languageCodes.count).",
                domain: .localization,
                sender: self
            )

            if let translate {
                return try await translate($0)
            }

            return try await translator.translate(
                .init(input),
                languagePair: .init(
                    from: languageCode,
                    to: $0
                )
            )
        }.reduce(into: [String: String]()) { partialResult, translation in
            var processedOutput = process(translation.output, with: processingConfig)
            if let postProcess {
                processedOutput = postProcess(processedOutput)
            }

            partialResult[translation.languagePair.to] = processedOutput
        }

        Logger.closeStream(
            message: "All strings should be translated; complete.",
            domain: .localization,
            onLine: #line
        )

        let whitespaceSeparatedComponents = input
            .components(separatedBy: .whitespaces)
            .map { $0.filter(\.isLetter) }

        let derivedKey = (
            whitespaceSeparatedComponents.count >= 3 ?
                Array(whitespaceSeparatedComponents[0 ... 2]) :
                whitespaceSeparatedComponents
        )
        .filter { !$0.isBlank }
        .joined(separator: "_")
        .lowercased()

        propertyList[key ?? derivedKey] = translationOutputsByLanguageCode
        return try createPLIST(
            from: propertyList,
            fileName: plistConfig.name,
            overwriteExistingFile: plistConfig.overwriteExistingFile
        )
    }

    // MARK: - Auxiliary

    private static func createPLIST(
        from dictionary: [String: [String: String]],
        fileName: String,
        overwriteExistingFile: Bool
    ) throws(Exception) -> String {
        @Dependency(\.fileManager) var fileManager: FileManager

        let filePathURL = URL.temporaryDirectory.appending(path: "/\(fileName).plist")
        let filePathString = filePathURL.path()

        if !overwriteExistingFile {
            guard !fileManager.fileExists(atPath: filePathString) else {
                throw Exception(
                    "File already exists.",
                    userInfo: ["FilePath": filePathString],
                    metadata: .init(sender: self)
                )
            }
        } else if fileManager.fileExists(atPath: filePathString) {
            do {
                try fileManager.removeItem(at: filePathURL)
            } catch {
                throw Exception(
                    error,
                    userInfo: ["FilePath": filePathString],
                    metadata: .init(sender: self)
                )
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

        return filePathString
    }

    private static func process(
        _ string: String,
        with configuration: ProcessingConfiguration?
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

        return stringComponents
            .filter { !$0.isBlank }
            .joined(separator: " ")
    }
}
