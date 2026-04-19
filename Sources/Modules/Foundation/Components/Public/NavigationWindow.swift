//
//  NavigationWindow.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/* Proprietary */
import ComponentKit

/// A view that wraps its content in a `NavigationView` with configurable
/// toolbar items, title, and display mode.
///
/// Use `NavigationWindow` as the outermost navigation container when
/// you need declarative control over the toolbar's contents and
/// appearance:
///
/// ```swift
/// NavigationWindow(
///     toolbarTitle: .init("Settings"),
///     toolbarItems: [
///         .init(placement: .topBarTrailing) {
///             Button("Done") { dismiss() }
///         },
///     ]
/// ) {
///     SettingsContentView()
/// }
/// ```
///
/// The view applies the app's accent color to the navigation
/// bar automatically.
///
/// - SeeAlso: ``Toolbar``, ``Toolbar/Item``,
///   ``Toolbar/TitleConfiguration``
public struct NavigationWindow: View {
    // MARK: - Properties

    private let content: () -> any View
    private let displayMode: NavigationBarItem.TitleDisplayMode
    private let isBackButtonHidden: Bool
    private let toolbarBackgroundColor: Color?
    private let toolbarTitle: Toolbar.TitleConfiguration?
    private let toolbarItems: [Toolbar.Item]?

    // MARK: - Init

    /// Creates a navigation window with the given configuration.
    ///
    /// - Parameters:
    ///   - displayMode: The navigation bar title display mode. The
    ///     default is `.automatic`.
    ///   - isBackButtonHidden: A Boolean value that hides the back
    ///     button. The default is `false`.
    ///   - toolbarBackgroundColor: An optional background color for the
    ///     navigation bar.
    ///   - toolbarItems: An optional array of toolbar items to display.
    ///   - toolbarTitle: An optional title configuration for the
    ///     navigation bar.
    ///   - content: The content to display inside the navigation view.
    public init(
        displayMode: NavigationBarItem.TitleDisplayMode = .automatic,
        isBackButtonHidden: Bool = false,
        toolbarBackgroundColor: Color? = nil,
        toolbarItems: [Toolbar.Item]? = nil,
        toolbarTitle: Toolbar.TitleConfiguration? = nil,
        content: @escaping () -> any View
    ) {
        self.displayMode = displayMode
        self.isBackButtonHidden = isBackButtonHidden
        self.toolbarBackgroundColor = toolbarBackgroundColor
        self.toolbarItems = toolbarItems
        self.toolbarTitle = toolbarTitle
        self.content = content
    }

    // MARK: - View

    public var body: some View {
        NavigationView {
            content()
                .eraseToAnyView()
                .navigationBarTitleDisplayMode(displayMode)
                .ifLet(toolbarTitle) { contentView, toolbarTitle in
                    contentView
                        .navigationTitle(
                            Text(toolbarTitle.text)
                                .font(ComponentKit.Font.systemSemibold.model)
                                .foregroundStyle(toolbarTitle.color)
                        )
                }
                .ifLet(toolbarItems) { contentView, toolbarItems in
                    contentView
                        .toolbar { Toolbar(toolbarItems) }
                }
        }
        .accentColor(Color.accent)
        .ifLet(toolbarBackgroundColor) { navigationView, toolbarBackgroundColor in
            navigationView
                .toolbarBackground(toolbarBackgroundColor, for: .navigationBar)
        }
        .if(isBackButtonHidden) {
            $0
                .navigationBarBackButtonHidden()
        }
    }
}

public extension NavigationWindow {
    /// The toolbar content rendered inside a ``NavigationWindow``.
    ///
    /// `Toolbar` groups its items by placement – leading, principal,
    /// and trailing – and renders each group in the appropriate
    /// position on the navigation bar.
    struct Toolbar: ToolbarContent {
        // MARK: - Properties

        private let items: [NavigationWindow.Toolbar.Item]

        // MARK: - Computed Properties

        private var leadingItems: [NavigationWindow.Toolbar.Item] {
            items.filter { $0.placement.toolbarItemPlacement == .topBarLeading }
        }

        private var principalItems: [NavigationWindow.Toolbar.Item] {
            items.filter { $0.placement.toolbarItemPlacement == .principal }
        }

        private var trailingItems: [NavigationWindow.Toolbar.Item] {
            items.filter { $0.placement.toolbarItemPlacement == .topBarTrailing }
        }

        // MARK: - Init

        init(_ items: [NavigationWindow.Toolbar.Item]) {
            self.items = items
        }

        // MARK: - View

        @ToolbarContentBuilder
        public var body: some ToolbarContent {
            if !leadingItems.isEmpty {
                ToolbarItemGroup(placement: .topBarLeading) {
                    ForEach(leadingItems) {
                        $0.content().eraseToAnyView()
                    }
                }
            }

            if !principalItems.isEmpty {
                ToolbarItemGroup(placement: .principal) {
                    ForEach(principalItems) {
                        $0.content().eraseToAnyView()
                    }
                }
            }

            if !trailingItems.isEmpty {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    ForEach(trailingItems) {
                        $0.content().eraseToAnyView()
                    }
                }
            }
        }
    }
}

public extension NavigationWindow.Toolbar {
    /// A single item displayed in the navigation bar toolbar.
    ///
    /// Each item declares a ``Placement`` and a view-building closure.
    /// The toolbar groups items by their placement and renders them in
    /// the corresponding position.
    struct Item: Identifiable {
        // MARK: - Types

        /// The position of a toolbar item within the navigation bar.
        public enum Placement {
            /* MARK: Cases */

            /// Centered in the navigation bar.
            case principal

            /// Positioned on the leading edge of the navigation bar.
            case topBarLeading

            /// Positioned on the trailing edge of the navigation bar.
            case topBarTrailing

            /* MARK: Properties */

            var toolbarItemPlacement: ToolbarItemPlacement {
                switch self {
                case .principal: .principal
                case .topBarLeading: .topBarLeading
                case .topBarTrailing: .topBarTrailing
                }
            }
        }

        // MARK: - Properties

        public let id: AnyHashable

        let content: () -> any View
        let placement: Placement

        // MARK: - Init

        /// Creates a toolbar item with the given placement and content.
        ///
        /// - Parameters:
        ///   - placement: The position of the item in the navigation
        ///     bar.
        ///   - content: A closure that returns the view to display.
        public init(
            placement: Placement,
            content: @escaping () -> any View
        ) {
            id = placement.hashValue
            self.placement = placement
            self.content = content
        }
    }
}

public extension NavigationWindow.Toolbar {
    /// The text and color configuration for a navigation bar title.
    struct TitleConfiguration {
        // MARK: - Properties

        let color: Color
        let text: String

        // MARK: - Init

        /// Creates a title configuration with the given text and color.
        ///
        /// - Parameters:
        ///   - text: The title string.
        ///   - color: The title color. The default is the theme's
        ///     navigation bar title color.
        @MainActor
        public init(
            _ text: String,
            color: Color = .navigationBarTitle
        ) {
            self.text = text
            self.color = color
        }
    }
}

extension ToolbarItemPlacement: @retroactive Equatable {
    public static func == (
        left: ToolbarItemPlacement,
        right: ToolbarItemPlacement
    ) -> Bool {
        String(describing: left) == String(describing: right)
    }
}
