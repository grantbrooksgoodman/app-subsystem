//
//  Localized.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

@propertyWrapper
public struct Localized<T: LocalizedStringKeyRepresentable>: Equatable {
    // MARK: - Properties

    private let key: T
    private let languageCode: String

    // MARK: - Init

    public init(
        key: T,
        languageCode: String
    ) {
        self.key = key
        self.languageCode = languageCode
    }

    // MARK: - WrappedValue

    public var wrappedValue: String {
        Localization.string(for: key, language: languageCode)
    }
}
