//
//  Primitives+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/* Proprietary */
import Translator

// MARK: - Float

public extension Float {
    /// A formatted duration string in `H:MM:SS` or `M:SS` format.
    var durationString: String {
        if self < 60 {
            return String(format: "0:%.02d", Int(rounded(.up)))
        } else if self < 3600 {
            return String(format: "%.02d:%.02d", Int(self / 60), Int(self) % 60)
        } else {
            let hours = Int(self / 3600)
            let remainingMinutesInSeconds = Int(self) - hours * 3600

            return String(
                format: "%.02d:%.02d:%.02d",
                hours,
                Int(remainingMinutesInSeconds / 60),
                Int(remainingMinutesInSeconds) % 60
            )
        }
    }
}

// MARK: - Int

public extension Int {
    /// The integer with an English ordinal suffix, such as "1st"
    /// or "3rd".
    var ordinalValueString: String {
        var suffix = "th"

        switch self % 10 {
        case 1:
            suffix = "st"
        case 2:
            suffix = "nd"
        case 3:
            suffix = "rd"
        default: ()
        }

        if (self % 100) > 10, (self % 100) < 20 {
            suffix = "th"
        }

        return String(self) + suffix
    }
}

// MARK: - String

// Implementation inherited from Translator.
extension String: EncodedHashable {}

public extension String {
    /* MARK: Properties */

    /// The 1-based position of the character in the English
    /// alphabet, or `nil` if not alphabetical.
    var alphabeticalPosition: Int? {
        guard count == 1 else { return nil }

        let alphabet = Array("abcdefghijklmnopqrstuvwxyz")
        let character = Character(lowercased())

        guard alphabet.contains(character),
              let index = alphabet.firstIndex(of: character) else { return nil }

        return index + 1
    }

    /// The string with spaces inserted before uppercase letters.
    var camelCaseToHumanReadable: String {
        components.reduce(into: [String]()) { partialResult, component in
            if component.isLowercase {
                partialResult.append(component)
            } else {
                partialResult.append(" \(component)")
            }
        }.joined()
    }

    /// An array of single-character strings.
    var components: [String] {
        map { String($0) }
    }

    /// The string with all non-digit characters removed.
    var digits: String {
        components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }

    /// For example, "Spanish" for devices with Spanish language codes.
    var englishLanguageName: String? {
        guard !isEmpty,
              !lowercasedTrimmingWhitespaceAndNewlines.isEmpty,
              let languageCodes = RuntimeStorage.languageCodeDictionary,
              let name = languageCodes[self] ?? languageCodes[lowercasedTrimmingWhitespaceAndNewlines] else { return nil }

        let components = name.components(separatedBy: " (")
        guard !components.isEmpty else { return name.trimmingBorderedWhitespace }
        return components[0].trimmingBorderedWhitespace
    }

    /// The string with its first character lowercased.
    var firstLowercase: String {
        prefix(1).lowercased() + dropFirst()
    }

    /// The string with its first character uppercased.
    var firstUppercase: String {
        prefix(1).uppercased() + dropFirst()
    }

    /// A Boolean value indicating whether the string is a single
    /// alphabetical character.
    var isAlphabetical: Bool {
        "A" ... "Z" ~= self || "a" ... "z" ~= self
    }

    /// A Boolean value indicating whether the string is empty or
    /// contains only whitespace.
    var isBlank: Bool {
        lowercasedTrimmingWhitespaceAndNewlines.isEmpty
    }

    /// A Boolean value indicating whether the string is entirely
    /// lowercase.
    var isLowercase: Bool {
        self == lowercased()
    }

    /// A Boolean value indicating whether the string is entirely
    /// uppercase.
    var isUppercase: Bool {
        self == uppercased()
    }

    /// For example, "Español" for devices with English language codes.
    var languageEndonym: String? {
        guard let languageName else { return nil }
        var components = languageName.components(separatedBy: " (")
        guard components.count > 1 else { return nil }
        components = components[1].components(separatedBy: ")")
        return components[0].trimmingBorderedWhitespace
    }

    /// For example, "Spanish" for devices with English language codes.
    var languageExonym: String? {
        guard let languageName else { return nil }
        let components = languageName.components(separatedBy: " (")
        guard !components.isEmpty else { return languageName }
        return components[0].trimmingBorderedWhitespace
    }

    /// For example, "Spanish (Español)" for devices with English language codes.
    var languageName: String? {
        @Dependency(\.coreKit.utils) var coreUtilities: CoreKit.Utilities

        guard !isEmpty,
              !lowercasedTrimmingWhitespaceAndNewlines.isEmpty,
              let languageCodes = coreUtilities.localizedLanguageCodeDictionary,
              let name = languageCodes[self] ?? languageCodes[lowercasedTrimmingWhitespaceAndNewlines] else { return nil }

        return name.trimmingBorderedWhitespace
    }

    /// The string lowercased with whitespace and newlines removed.
    var lowercasedTrimmingWhitespaceAndNewlines: String {
        lowercased().trimmingWhitespace.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The string with translation-related sentinel characters removed.
    var sanitized: String {
        removingOccurrences(of: ["⁂", "⌘", "※"])
    }

    /// The string converted from camel case to snake case.
    var snakeCased: String {
        var characters = components
        func satisfiesConstraints(_ character: String) -> Bool {
            character.isAlphabetical && character.isUppercase
        }

        for (index, character) in characters.enumerated() where satisfiesConstraints(character) {
            characters[index] = "_\(character.lowercased())"
        }

        return characters.joined()
    }

    /// The string with leading and trailing whitespace removed.
    var trimmingBorderedWhitespace: String {
        trimmingLeadingWhitespace.trimmingTrailingWhitespace
    }

    /// The string with leading whitespace removed.
    var trimmingLeadingWhitespace: String {
        var string = self
        while string.hasPrefix(" ") || string.hasPrefix("\u{00A0}") {
            string = string.dropPrefix()
        }
        return string
    }

    /// The string with trailing whitespace removed.
    var trimmingTrailingWhitespace: String {
        var string = self
        while string.hasSuffix(" ") || string.hasSuffix("\u{00A0}") {
            string = string.dropSuffix()
        }
        return string
    }

    /// The string with all whitespace characters removed.
    var trimmingWhitespace: String {
        replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\u{00A0}", with: "")
    }

    /* MARK: Methods */

    /// Creates a cleaned type-name string from the given value,
    /// stripping module prefixes, parenthesized suffixes, and
    /// unbalanced wrapper characters.
    init(_ type: some Any) {
        @Dependency(\.mainBundle) var mainBundle: Bundle

        var descriptor = String(describing: type)
        let targetName = mainBundle.infoDictionary?["CFTargetName"] as? String

        if let targetName {
            descriptor = descriptor.removingOccurrences(of: [
                "AppSubsystem.",
                "Swift.",
                "\(targetName).",
            ])
        }

        descriptor = descriptor.components(separatedBy: "(").first ?? descriptor

        // If the string ends in a balanced generic suffix like "<...>",
        // temporarily peel it off so trimming doesn't eat trailing ">" / ">>".
        let (_head, suffix) = descriptor.peelTrailingBalancedGenericSuffix()
        var head = _head

        // Repeatedly apply the trim rules until stable (on head only).
        while true {
            guard let firstCharacter = head.first,
                  let lastCharacter = head.last else { break }

            if !firstCharacter.isLetter,
               lastCharacter.isLetter {
                head = head.dropPrefix()
                continue
            }

            if firstCharacter.isLetter,
               !lastCharacter.isLetter {
                head = head.dropSuffix()
                continue
            }

            if !firstCharacter.isLetter,
               !lastCharacter.isLetter,
               !firstCharacter.isFlipSideMatch(with: lastCharacter),
               firstCharacter != lastCharacter {
                head = head.dropPrefix().dropSuffix()
                continue
            }

            break
        }

        self.init(head + suffix)
    }

    /// Returns an attributed string configured with the given
    /// primary and secondary attributes.
    func attributed(_ config: AttributedStringConfig) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(
            string: self,
            attributes: config.primaryAttributes
        )

        func applyAttributes(
            _ attributes: [NSAttributedString.Key: Any],
            stringRanges: [String]
        ) {
            stringRanges.filter { self.contains($0) }.forEach { string in
                attributedString.addAttributes(
                    attributes,
                    range: (self as NSString).range(of: (string as NSString) as String)
                )
            }
        }

        config.secondaryAttributes?.forEach {
            applyAttributes(
                $0.attributes,
                stringRanges: $0.stringRanges
            )
        }

        return attributedString
    }

    /// Returns the string with each UTF-8 byte shifted by the given
    /// modifier, wrapping around the lowercase ASCII range.
    func ciphered(by modifier: Int) -> String {
        String(utf8.reduce(into: [Character]()) { partialResult, utf8Value in
            let shiftedValue = Int(utf8Value) + modifier
            let wrapAroundBy = shiftedValue > 97 + 25 ? -26 : (shiftedValue < 97 ? 26 : 0)
            if let scalar = UnicodeScalar(shiftedValue + wrapAroundBy) {
                partialResult.append(.init(scalar))
            }
        })
    }

    /// Returns `true` if the string contains any character from the
    /// given string.
    func containsAnyCharacter(in string: String) -> Bool {
        !components.filter { string.components.contains($0) }.isEmpty
    }

    /// Returns the string with the first `dropping` characters
    /// removed.
    func dropPrefix(_ dropping: Int = 1) -> String {
        guard count > dropping else { return "" }
        return String(suffix(from: index(startIndex, offsetBy: dropping)))
    }

    /// Returns the string with the last `dropping` characters
    /// removed.
    func dropSuffix(_ dropping: Int = 1) -> String {
        guard count > dropping else { return "" }
        return String(prefix(count - dropping))
    }

    /// Returns `true` if the string is equal to any string in the
    /// given array.
    func isAnyString(in array: [String]) -> Bool {
        !array.filter { self == $0 }.isEmpty
    }

    /// Returns the string with all occurrences of the given strings
    /// removed.
    func removingOccurrences(of excludedStrings: [String]) -> String {
        var string = self
        excludedStrings.forEach { string = string.replacingOccurrences(of: $0, with: "") }
        return string
    }
}

private extension Character {
    func isFlipSideMatch(with otherCharacter: Character) -> Bool {
        let wrapperPairs: [Character: Character] = [
            "(": ")",
            "[": "]",
            "{": "}",
            "<": ">",
            "“": "”",
            "‘": "’",
        ]

        // Forward match: opening -> closing.
        if let closingCharacter = wrapperPairs[self],
           closingCharacter == otherCharacter {
            return true
        }

        // Reverse match: closing -> opening.
        if let closingCharacter = wrapperPairs[otherCharacter],
           closingCharacter == self {
            return true
        }

        // Treat same-character wrappers as matching (quotes, pipes, etc.).
        let symmetricallyWrapped: Set<Character> = ["\"", "'", "|", "`"]
        if self == otherCharacter,
           symmetricallyWrapped.contains(self) {
            return true
        }

        return false
    }
}

private extension String {
    func peelTrailingBalancedGenericSuffix() -> (head: String, suffix: String) {
        guard last == ">" else { return (self, "") }

        // Walk backwards to find the matching '<' for the last '>'.
        var depth = 0
        var index = index(before: endIndex)

        while true {
            let character = self[index]
            if character == ">" {
                depth += 1
            } else if character == "<" {
                depth -= 1
                if depth == 0 {
                    // index is the '<' that matches the trailing generic block.
                    return (
                        String(self[..<index]),
                        String(self[index...])
                    )
                }
            }

            if index == startIndex { break }
            index = self.index(before: index)
        }

        // Not balanced (or no matching '<'), don't peel.
        return (self, "")
    }
}
