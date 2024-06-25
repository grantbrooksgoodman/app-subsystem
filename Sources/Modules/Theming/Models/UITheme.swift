//
//  UITheme.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

public struct UITheme: CaseIterable, Equatable, EncodedHashable {
    // MARK: - Properties

    public let name: String
    public let items: [ColoredItem]
    public let style: UIUserInterfaceStyle

    // MARK: - Computed Properties

    public static var allCases: [UITheme] {
        (AppSubsystem.delegates.uiThemeList.uiThemes + UITheme.subsystemCases).unique
    }

    // MARK: - EncodedHashable Conformance

    public var hashFactors: [String] {
        var factors = [String]()
        factors.append(name)
        factors.append(contentsOf: items.map(\.set.primary).map { String($0.hash) })
        factors.append(contentsOf: items.compactMap(\.set.variant).map { String($0.hash) })
        factors.append(contentsOf: items.map(\.type.rawValue))
        factors.append(.init(style.rawValue))
        return factors
    }

    // MARK: - Init

    public init(
        name: String,
        items: [ColoredItem],
        style: UIUserInterfaceStyle = .unspecified
    ) {
        self.name = name
        self.items = items
        self.style = style
        assert(!containsDuplicates(items: self.items), "Cannot instantiate UITheme with duplicate ColoredItems")
    }

    // MARK: - Color for Item

    /// - Warning: Returns `UIColor.clear` if item is not themed.
    public func color(for itemType: ColoredItemType) -> UIColor {
        guard let item = items.first(where: { $0.type == itemType }) else { return .clear }
        return ThemeService.isDarkModeActive ? (item.set.variant ?? item.set.primary) : item.set.primary
    }

    // MARK: - Auxiliary

    private func containsDuplicates(items: [ColoredItem]) -> Bool {
        let types = items.map(\.type)
        return types.unique.count != types.count
    }
}

public extension UITheme {
    // MARK: - Type Aliases

    private typealias Item = UITheme.ColoredItem

    // MARK: - Properties

    static let `default`: UITheme = .init(name: "Default", items: defaultColoredItems)

    private static var defaultColoredItems: [Item] {
        let accent = Item(.accent, set: .init(.systemBlue))
        let background = Item(.background, set: .init(.white, variant: .black))
        let disabled = Item(.disabled, set: .init(.systemGray3))
        let groupedContentBackground = Item(.groupedContentBackground, set: .init(.init(hex: 0xF2F2F7), variant: .init(hex: 0x1C1C1E)))

        let navigationBarBackground = Item(.navigationBarBackground, set: .init(.init(hex: 0xF8F8F8), variant: .init(hex: 0x2A2A2C)))
        let navigationBarTitle = Item(.navigationBarTitle, set: .init(.black, variant: .white))

        let titleText = Item(.titleText, set: .init(.black, variant: .white))
        let subtitleText = Item(.subtitleText, set: .init(.systemGray))

        return [
            accent,
            background,
            disabled,
            groupedContentBackground,
            navigationBarBackground,
            navigationBarTitle,
            titleText,
            subtitleText,
        ]
    }
}

extension UITheme {
    static var subsystemCases: [UITheme] { [.default] }
}
