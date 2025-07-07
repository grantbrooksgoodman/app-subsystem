//
//  ForcedUpdateModalPageViewStrings.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/* Proprietary */
import Translator

public extension TranslatedLabelStringCollection {
    enum ForcedUpdateModalPageViewStringKey: String, Equatable, CaseIterable, TranslatedLabelStringKey {
        // MARK: - Cases

        case installButtonText
        case subtitleLabelText
        case titleLabelText

        // MARK: - Properties

        public var alternate: String? { nil }

        public var rawValue: String {
            @Dependency(\.build) var build: Build
            var productName = "⌘\(build.finalName)⌘"
            if productName.sanitized.isBlank {
                productName = build.codeName.isBlank ? "the app" : "⌘\(build.codeName)⌘"
            }

            switch self {
            case .installButtonText:
                return "Install Now"

            case .subtitleLabelText:
                return "This version of \(productName) is no longer supported. To continue, please download and install the most recent update."

            case .titleLabelText:
                return RuntimeStorage.languageCode == "en" ? "Update Required" : "An Update is Required"
            }
        }
    }
}

enum ForcedUpdateModalPageViewStrings: TranslatedLabelStrings {
    static var keyPairs: [TranslationInputMap] {
        TranslatedLabelStringCollection.ForcedUpdateModalPageViewStringKey.allCases
            .map {
                TranslationInputMap(
                    key: .forcedUpdateModalPageView($0),
                    input: .init(
                        $0.rawValue,
                        alternate: $0.alternate
                    )
                )
            }
    }
}

extension TranslatedLabelStringCollection {
    static func forcedUpdateModalPageView(_ key: ForcedUpdateModalPageViewStringKey) -> TranslatedLabelStringCollection { .init(key.rawValue) }
}
