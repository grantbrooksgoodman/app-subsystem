//
//  HeaderViewModifier.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/* Proprietary */
import ComponentKit

private struct HeaderViewModifier: ViewModifier {
    // MARK: - Constants Accessors

    private typealias Floats = FoundationConstants.CGFloats.HeaderViewModifier
    private typealias Strings = FoundationConstants.Strings.HeaderViewModifier

    // MARK: - Dependencies

    @Dependency(\.uiApplication.mainScreen.bounds.width) private var screenWidth: CGFloat

    // MARK: - Properties

    private let attributes: HeaderView.Attributes
    private let centerItem: HeaderView.CenterItemType?
    private let leftItem: HeaderView.PeripheralButtonType?
    private let popGestureAction: (() -> Void)?
    private let rightItem: HeaderView.PeripheralButtonType?
    private let usesInlineDisplayMode: Bool
    private let usesV26Attributes: Bool

    // MARK: - Computed Properties

    private var imageMaxWidth: CGFloat {
        screenWidth / Floats.imageMaxWidthDivisor
    }

    private var isThemed: Bool {
        attributes.appearance == .themed
    }

    private var navigationBarAppearance: NavigationBarAppearance {
        var backgroundColor = attributes.appearance.backgroundColor
        if attributes.appearance.backgroundColor == .navigationBarBackground || isThemed {
            backgroundColor = .clear
        }

        let configuration: NavigationBarConfiguration = .init(
            titleColor: textColor ?? .navigationBarTitle,
            backgroundColor: backgroundColor,
            barButtonItemColor: textColor ?? .accent,
            showsDivider: attributes.showsDivider
        )

        return .custom(
            configuration,
            scrollEdgeConfig: configuration
        )
    }

    private var textColor: UIColor? {
        var colors = Set<Color>()

        if let leftItemForegroundColor = leftItem?.foregroundColor {
            colors.insert(leftItemForegroundColor)
        }

        if let centerItem {
            if let subtitleForegroundColor = centerItem.subtitleForegroundColor {
                colors.insert(subtitleForegroundColor)
            }

            if let titleForegroundColor = centerItem.titleForegroundColor {
                colors.insert(titleForegroundColor)
            }
        }

        if let rightItemForegroundColor = rightItem?.foregroundColor {
            colors.insert(rightItemForegroundColor)
        }

        guard colors.count == 1,
              let color = colors.first else { return nil }

        return .init(color)
    }

    // MARK: - Init

    init(
        leftItem: HeaderView.PeripheralButtonType?,
        centerItem: HeaderView.CenterItemType?,
        rightItem: HeaderView.PeripheralButtonType?,
        attributes: HeaderView.Attributes,
        popGestureAction: (() -> Void)?,
        usesInlineDisplayMode: Bool,
        usesV26Attributes: Bool
    ) {
        self.leftItem = leftItem
        self.centerItem = centerItem
        self.rightItem = rightItem
        // TODO: I don't think we need to do this anymore.
        self.attributes = UIApplication.isFullyV26Compatible && usesV26Attributes ? .init(
            appearance: attributes.appearance.backgroundColor == .navigationBarBackground ||
                attributes.appearance == .themed ?
                .custom(backgroundColor: .clear) :
                attributes.appearance,
            restoreOnDisappear: attributes.restoreOnDisappear,
            showsDivider: false,
            sizeClass: attributes.sizeClass
        ) : attributes
        self.popGestureAction = popGestureAction
        self.usesInlineDisplayMode = usesInlineDisplayMode
        self.usesV26Attributes = usesV26Attributes
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .if(
                UIApplication.isFullyV26Compatible && usesInlineDisplayMode,
                { content in
                    NavigationWindow(
                        displayMode: .inline,
                        isBackButtonHidden: true,
                        toolbarItems: [
                            leadingToolbarItem,
                            principalToolbarItem,
                            trailingToolbarItem,
                        ].compactMap { $0 }
                    ) {
                        ZStack(alignment: .top) {
                            Color.clear
                                .frame(width: .zero, height: .zero)
                                .ignoresSafeArea(edges: .top)
                                .navigationBarAppearance(
                                    navigationBarAppearance,
                                    restoreOnDisappear: attributes.restoreOnDisappear
                                )

                            content

                            Rectangle()
                                .fill(Color(uiColor: attributes.appearance.backgroundColor))
                                .frame(height:
                                    NavigationBar.height + Floats.navigationBarHeightIncrement
                                )
                                .ignoresSafeArea(edges: .top)
                        }
                    }
                    .ifLet(popGestureAction) { content, popGestureAction in
                        content.popGesture(
                            popGestureAction
                        )
                    }
                },
                else: {
                    $0
                        .header(
                            leftItem: leftItem,
                            centerItem,
                            rightItem: rightItem,
                            attributes: attributes,
                            popGestureAction: popGestureAction
                        )
                }
            )
    }

    // MARK: - Toolbar Items

    private var leadingToolbarItem: NavigationWindow.Toolbar.Item? {
        guard let leftItem else { return nil }
        return .init(placement: .topBarLeading) {
            peripheralToolbarButton(for: leftItem, isLeadingItem: true)
        }
    }

    private var principalToolbarItem: NavigationWindow.Toolbar.Item? {
        guard let centerItem,
              let navigationTitle = centerItem.navigationTitle else { return nil }

        return .init(placement: .principal) {
            Components.text(
                navigationTitle,
                font: .systemSemibold,
                foregroundColor: centerItem.titleForegroundColor ?? .navigationBarTitle
            )
        }
    }

    private var trailingToolbarItem: NavigationWindow.Toolbar.Item? {
        guard let rightItem else { return nil }
        return .init(placement: .topBarTrailing) {
            peripheralToolbarButton(for: rightItem, isLeadingItem: false)
        }
    }

    // MARK: - Auxiliary

    private func peripheralToolbarButton(
        for type: HeaderView.PeripheralButtonType,
        isLeadingItem: Bool
    ) -> some View {
        let cancelString = Localized(SubsystemStringKey.cancel).wrappedValue
        let doneString = Localized(SubsystemStringKey.done).wrappedValue

        return Group {
            switch type {
            case let .image(attributes):
                Button {
                    attributes.action()
                } label: {
                    attributes.image.image
                        .resizable()
                        .scaledToFit()
                        .fontWeight(attributes.image.weight)
                        .foregroundStyle(isThemed ? (attributes.isEnabled ? .accent : .disabled) : attributes.image.foregroundColor)
                        .ifLet(attributes.image.size) { image, size in
                            image
                                .frame(
                                    width: size.width > imageMaxWidth ? nil : size.width,
                                    height: size.height > Floats.toolbarButtonHeight ? nil : size.height
                                )
                        }
                        .frame(
                            maxWidth: imageMaxWidth,
                            maxHeight: Floats.toolbarButtonHeight,
                            alignment: isLeadingItem ? .leading : .trailing
                        )
                }
                .disabled(!attributes.isEnabled)

            case let .text(attributes):
                if attributes.text.string == cancelString ||
                    attributes.text.string == doneString {
                    Components.button(
                        symbolName: attributes.text.string == cancelString ?
                            Strings.cancelToolbarButtonImageSystemName :
                            Strings.doneToolbarButtonImageSystemName,
                        foregroundColor: isThemed ? (attributes.isEnabled ? .accent : .disabled) : attributes.text.foregroundColor,
                        weight: .semibold,
                        usesIntrinsicSize: false
                    ) {
                        attributes.action()
                    }
                    .disabled(!attributes.isEnabled)
                    .frame(
                        width: Floats.toolbarButtonWidth,
                        height: Floats.toolbarButtonHeight
                    )
                } else {
                    Button {
                        attributes.action()
                    } label: {
                        Text(attributes.text.string)
                            .font(attributes.text.font)
                            .foregroundStyle(isThemed ? (attributes.isEnabled ? .accent : .disabled) : attributes.text.foregroundColor)
                            .lineLimit(1)
                            .minimumScaleFactor(Floats.toolbarButtonLabelMinimumScaleFactor)
                            .padding(.horizontal, Floats.toolbarButtonLabelHorizontalPadding)
                    }
                    .disabled(!attributes.isEnabled)
                }
            }
        }
    }
}

public extension View {
    /// Applies a configurable header to the view, with support for
    /// leading, center, and trailing items.
    ///
    /// On iOS 26 and later, the header uses an inline navigation bar
    /// with toolbar items. On earlier versions, it falls back to a
    /// custom ``HeaderView``.
    ///
    /// - Parameters:
    ///   - leftItem: The button displayed on the leading edge.
    ///   - centerItem: The title or image displayed in the center.
    ///   - rightItem: The button displayed on the trailing edge.
    ///   - attributes: The header's visual configuration. Choosing a
    ///     themed `appearance` overrides all color values to those of
    ///     the active theme.
    ///   - popGestureAction: A closure to execute when the user
    ///     performs a pop gesture.
    ///   - usesInlineDisplayMode: Whether to use an inline
    ///     navigation bar on iOS 26 and later. The default is `true`.
    ///   - usesV26Attributes: Whether to adapt the attributes for
    ///     iOS 26. The default is `true`.
    func header(
        leftItem: HeaderView.PeripheralButtonType? = nil,
        _ centerItem: HeaderView.CenterItemType? = nil,
        rightItem: HeaderView.PeripheralButtonType? = nil,
        attributes: HeaderView.Attributes = .init(),
        popGestureAction: (() -> Void)? = nil,
        usesInlineDisplayMode: Bool = true,
        usesV26Attributes: Bool = true
    ) -> some View {
        modifier(
            HeaderViewModifier(
                leftItem: leftItem,
                centerItem: centerItem,
                rightItem: rightItem,
                attributes: attributes,
                popGestureAction: popGestureAction,
                usesInlineDisplayMode: usesInlineDisplayMode,
                usesV26Attributes: usesV26Attributes
            )
        )
    }
}

private extension HeaderView.CenterItemType {
    var navigationTitle: String? {
        switch self {
        case .image: nil
        case let .text(titleTextAttributes, subtitle: _): titleTextAttributes.string
        }
    }

    var subtitleForegroundColor: Color? {
        switch self {
        case .image: nil
        case let .text(_, subtitle: subtitleTextAttributes): subtitleTextAttributes?.foregroundColor
        }
    }

    var titleForegroundColor: Color? {
        switch self {
        case .image: nil
        case let .text(titleTextAttributes, subtitle: _): titleTextAttributes.foregroundColor
        }
    }
}

private extension HeaderView.PeripheralButtonType {
    var foregroundColor: Color? {
        switch self {
        case .image: nil
        case let .text(attributes): attributes.text.foregroundColor
        }
    }
}
