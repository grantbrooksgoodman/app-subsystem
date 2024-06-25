//
//  AppTheme.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public struct AppTheme: CaseIterable, Equatable {
    // MARK: - Properties

    public let theme: UITheme

    // MARK: - Computed Properties

    public static var allCases: [AppTheme] {
        (AppSubsystem.delegates.appThemeList.appThemes + AppTheme.subsystemCases).unique
    }

    // MARK: - Init

    public init(_ theme: UITheme) {
        self.theme = theme
    }
}

public extension AppTheme {
    // MARK: - Type Aliases

    private typealias Item = UITheme.ColoredItem

    // MARK: - Properties

    static let `default`: AppTheme = .init(.init(name: "Default", items: defaultColoredItems))

    private static var defaultColoredItems: [Item] {
        let accent = Item(type: .accent, set: .init(primary: .systemBlue))
        let background = Item(type: .background, set: .init(primary: .white, variant: .black))
        let disabled = Item(type: .disabled, set: .init(primary: .systemGray3))

        let navigationBarBackground = Item(type: .navigationBarBackground, set: .init(primary: .init(hex: 0xF8F8F8), variant: .init(hex: 0x2A2A2C)))
        let navigationBarTitle = Item(type: .navigationBarTitle, set: .init(primary: .black, variant: .white))

        let titleText = Item(type: .titleText, set: .init(primary: .black, variant: .white))
        let subtitleText = Item(type: .subtitleText, set: .init(primary: .systemGray))

        return [
            accent,
            background,
            disabled,
            navigationBarBackground,
            navigationBarTitle,
            titleText,
            subtitleText,
        ]
    }
}

extension AppTheme {
    static var subsystemCases: [AppTheme] { [.default] }
}
