//
//  UITheme.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

/// A named collection of colors that defines the visual appearance of an
/// app.
///
/// A theme maps semantic color slots (``ColoredItemType``) to concrete
/// colors through an array of ``ColoredItem`` values. Each item pairs a
/// slot with a ``ColorSet`` that can provide separate colors for light and
/// dark appearances.
///
/// ## Defining a Theme
///
/// Create a theme by providing a name, a list of colored items, and an
/// optional interface style:
///
/// ```swift
/// let oceanTheme = UITheme(
///     name: "Ocean",
///     items: [
///         .init(.accent, set: .init(.systemTeal)),
///         .init(.background, set: .init(.white, variant: .init(hex: 0x0A1628))),
///         .init(.titleText, set: .init(.black, variant: .white)),
///     ],
///     style: .unspecified
/// )
/// ```
///
/// Register custom themes by providing a ``UIThemeListDelegate`` to
/// ``AppSubsystem/delegates``. All registered themes are available through
/// ``allCases``.
///
/// ## Resolving Colors
///
/// Use ``color(for:)`` to resolve a ``ColoredItemType`` against the
/// theme's palette. The method automatically returns the dark mode variant
/// when appropriate:
///
///     let accentColor = ThemeService.currentTheme.color(for: .accent)
///
/// For convenience, themed colors are also available as static properties
/// on `UIColor` and `Color`:
///
/// ```swift
/// label.textColor = .titleText    // UIKit
/// Text("Hello").foregroundStyle(.accent)  // SwiftUI
/// ```
///
/// - Warning: ``color(for:)`` returns `UIColor.clear` if the requested
///   item type is not present in the theme's palette. Ensure that every
///   theme provides colors for all item types your app uses.
public struct UITheme: CaseIterable, Equatable, @MainActor EncodedHashable, Sendable {
    // MARK: - Properties

    /// The display name of the theme.
    public let name: String

    /// The colored items that make up this theme's palette.
    public let items: Set<ColoredItem>

    /// The user interface style this theme applies.
    ///
    /// A value of `unspecified` follows the system appearance. Setting a
    /// specific style forces the app into light or dark mode
    /// regardless of the system setting.
    public let style: UIUserInterfaceStyle

    // MARK: - Computed Properties

    /// All available themes, including both app-provided and subsystem
    /// themes.
    public static var allCases: [UITheme] {
        (AppSubsystem.delegates.uiThemeList.uiThemes + UITheme.subsystemCases).unique
    }

    // MARK: - EncodedHashable Conformance

    @MainActor
    public var hashFactors: [String] {
        var factors = [String]()
        factors.append(name)
        factors.append(contentsOf: items.map(\.set.primary.encodedHash))
        factors.append(contentsOf: items.compactMap(\.set.variant?.encodedHash))
        factors.append(contentsOf: items.map(\.type.rawValue))
        factors.append(.init(style.rawValue))
        return factors.sorted()
    }

    // MARK: - Init

    /// Creates a theme with the given name, colored items, and interface
    /// style.
    ///
    /// - Parameters:
    ///   - name: The display name of the theme.
    ///   - items: The colored items that make up the palette. Each item
    ///     type must appear at most once.
    ///   - style: The user interface style to apply. Pass `unspecified` to
    ///     follow the system appearance. Defaults to `unspecified`.
    public init(
        name: String,
        items: Set<ColoredItem>,
        style: UIUserInterfaceStyle = .unspecified
    ) {
        self.name = name
        self.items = items
        self.style = style
        assert(
            !containsDuplicates(items: items),
            "Cannot instantiate UITheme with duplicate ColoredItems"
        )
    }

    // MARK: - Color for Item

    /// Returns the color for the given item type, selecting the appropriate
    /// appearance variant automatically.
    ///
    /// When dark mode is active, the variant color is returned if one was
    /// provided; otherwise the primary color is used.
    ///
    /// - Parameter itemType: The semantic color slot to resolve.
    ///
    /// - Returns: The resolved color, or `UIColor.clear` if `itemType` is
    ///   not present in this theme's palette.
    @MainActor
    public func color(for itemType: ColoredItemType) -> UIColor {
        guard let item = items.first(where: { $0.type == itemType }) else { return .clear }
        return ThemeService.isDarkModeActive ? (item.set.variant ?? item.set.primary) : item.set.primary
    }

    // MARK: - Auxiliary

    private func containsDuplicates(items: Set<ColoredItem>) -> Bool {
        let types = items.map(\.type)
        return types.unique.count != types.count
    }
}

public extension UITheme {
    // MARK: - Type Aliases

    private typealias Item = UITheme.ColoredItem

    // MARK: - Properties

    /// The built-in theme used when no other theme has been applied.
    static let `default`: UITheme = .init(
        name: "Default",
        items: defaultColoredItems
    )

    private static var defaultColoredItems: Set<Item> {
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
