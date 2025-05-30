//
//  Primitives+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import Translator

// MARK: - Float

public extension Float {
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

        if (self % 100) > 10 && (self % 100) < 20 {
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

    var alphabeticalPosition: Int? {
        guard count == 1 else { return nil }

        let alphabet = Array("abcdefghijklmnopqrstuvwxyz")
        let character = Character(lowercased())

        guard alphabet.contains(character),
              let index = alphabet.firstIndex(of: character) else { return nil }

        return index + 1
    }

    var camelCaseToHumanReadable: String {
        components.reduce(into: [String]()) { partialResult, component in
            if component.isLowercase {
                partialResult.append(component)
            } else {
                partialResult.append(" \(component)")
            }
        }.joined()
    }

    var components: [String] {
        map { String($0) }
    }

    var digits: String {
        components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }

    /// e.g. "Spanish" for devices with Spanish language codes.
    var englishLanguageName: String? {
        guard !isEmpty,
              !lowercasedTrimmingWhitespaceAndNewlines.isEmpty,
              let languageCodes = RuntimeStorage.languageCodeDictionary,
              let name = languageCodes[self] ?? languageCodes[lowercasedTrimmingWhitespaceAndNewlines] else { return nil }

        let components = name.components(separatedBy: " (")
        guard !components.isEmpty else { return name.trimmingBorderedWhitespace }
        return components[0].trimmingBorderedWhitespace
    }

    var firstLowercase: String {
        prefix(1).lowercased() + dropFirst()
    }

    var firstUppercase: String {
        prefix(1).uppercased() + dropFirst()
    }

    var isAlphabetical: Bool {
        "A" ... "Z" ~= self || "a" ... "z" ~= self
    }

    var isBlank: Bool {
        lowercasedTrimmingWhitespaceAndNewlines.isEmpty
    }

    var isLowercase: Bool {
        self == lowercased()
    }

    var isUppercase: Bool {
        self == uppercased()
    }

    /// e.g. "Español" for devices with English language codes.
    var languageEndonym: String? {
        guard let languageName else { return nil }
        var components = languageName.components(separatedBy: " (")
        guard components.count > 1 else { return nil }
        components = components[1].components(separatedBy: ")")
        return components[0].trimmingBorderedWhitespace
    }

    /// e.g. "Spanish" for devices with English language codes.
    var languageExonym: String? {
        guard let languageName else { return nil }
        let components = languageName.components(separatedBy: " (")
        guard !components.isEmpty else { return languageName }
        return components[0].trimmingBorderedWhitespace
    }

    /// e.g. "Spanish (Español)" for devices with English language codes.
    var languageName: String? {
        @Dependency(\.coreKit.utils) var coreUtilities: CoreKit.Utilities

        guard !isEmpty,
              !lowercasedTrimmingWhitespaceAndNewlines.isEmpty,
              let languageCodes = coreUtilities.localizedLanguageCodeDictionary,
              let name = languageCodes[self] ?? languageCodes[lowercasedTrimmingWhitespaceAndNewlines] else { return nil }

        return name.trimmingBorderedWhitespace
    }

    var lowercasedTrimmingWhitespaceAndNewlines: String {
        lowercased().trimmingWhitespace.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var sanitized: String {
        removingOccurrences(of: ["⁂", "⌘"])
    }

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

    var trimmingBorderedWhitespace: String {
        trimmingLeadingWhitespace.trimmingTrailingWhitespace
    }

    var trimmingLeadingWhitespace: String {
        var string = self
        while string.hasPrefix(" ") || string.hasPrefix("\u{00A0}") {
            string = string.dropPrefix()
        }
        return string
    }

    var trimmingTrailingWhitespace: String {
        var string = self
        while string.hasSuffix(" ") || string.hasSuffix("\u{00A0}") {
            string = string.dropSuffix()
        }
        return string
    }

    var trimmingWhitespace: String {
        replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\u{00A0}", with: "")
    }

    /* MARK: Methods */

    init<T>(_ type: T) {
        @Dependency(\.mainBundle) var mainBundle: Bundle

        let string = String(describing: type)
        guard let targetName = mainBundle.infoDictionary?["CFTargetName"] as? String else {
            self.init(string.components(separatedBy: "(")[0])
            return
        }

        self.init(string.removingOccurrences(of: ["\(targetName)."]).components(separatedBy: "(")[0])
    }

    func attributed(_ config: AttributedStringConfig) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self, attributes: config.primaryAttributes)
        func applyAttributes(_ attributes: [NSAttributedString.Key: Any], stringRanges: [String]) {
            stringRanges.filter { self.contains($0) }.forEach { string in
                attributedString.addAttributes(
                    attributes,
                    range: (self as NSString).range(of: (string as NSString) as String)
                )
            }
        }

        config.secondaryAttributes?.forEach { applyAttributes($0.attributes, stringRanges: $0.stringRanges) }
        return attributedString
    }

    func ciphered(by modifier: Int) -> String {
        String(utf8.reduce(into: [Character]()) { partialResult, utf8Value in
            let shiftedValue = Int(utf8Value) + modifier
            let wrapAroundBy = shiftedValue > 97 + 25 ? -26 : (shiftedValue < 97 ? 26 : 0)
            if let scalar = UnicodeScalar(shiftedValue + wrapAroundBy) {
                partialResult.append(.init(scalar))
            }
        })
    }

    func containsAnyCharacter(in string: String) -> Bool {
        !components.filter { string.components.contains($0) }.isEmpty
    }

    func dropPrefix(_ dropping: Int = 1) -> String {
        guard count > dropping else { return "" }
        return String(suffix(from: index(startIndex, offsetBy: dropping)))
    }

    func dropSuffix(_ dropping: Int = 1) -> String {
        guard count > dropping else { return "" }
        return String(prefix(count - dropping))
    }

    func isAnyString(in array: [String]) -> Bool {
        !array.filter { self == $0 }.isEmpty
    }

    func removingOccurrences(of excludedStrings: [String]) -> String {
        var string = self
        excludedStrings.forEach { string = string.replacingOccurrences(of: $0, with: "") }
        return string
    }
}
