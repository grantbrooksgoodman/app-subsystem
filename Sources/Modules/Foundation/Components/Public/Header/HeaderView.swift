//
//  HeaderView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI
import UIKit

/// A configurable header bar for use in sheets and full-screen covers.
///
/// `HeaderView` provides a standard layout consisting of an optional
/// left button, a center title or image, and an optional right button.
/// Its appearance adapts to the current theme when using the
/// ``Appearance/themed`` style:
///
/// ```swift
/// HeaderView(
///     leftItem: .text(.init("Cancel", font: .body) { dismiss() }),
///     centerItem: .text(.init("New Message")),
///     rightItem: .text(.init("Send") { send() }),
///     attributes: .init(sizeClass: .sheet)
/// )
/// ```
///
/// ## Appearance
///
/// Use ``Appearance/themed`` to inherit the navigation bar colors from
/// the active ``UITheme``, or ``Appearance/custom(backgroundColor:)``
/// to specify a color directly.
///
/// ## Size Class
///
/// The ``SizeClass`` controls the minimum height of the header. Use
/// ``SizeClass/sheet`` or ``SizeClass/fullScreenCover`` for standard
/// presentation contexts, or ``SizeClass/custom(minHeight:)`` for a
/// specific value.
public struct HeaderView: View {
    // MARK: - Types

    /// The visual appearance of the header's background.
    public enum Appearance: Equatable {
        /* MARK: Cases */

        /// A custom background color.
        case custom(backgroundColor: UIColor)

        /// The background color defined by the active theme.
        case themed

        /* MARK: Properties */

        @MainActor
        var backgroundColor: UIColor {
            switch self {
            case let .custom(
                backgroundColor: backgroundColor
            ): backgroundColor
            case .themed: .navigationBarBackground
            }
        }
    }

    /// The type of content displayed at the center of the header.
    public enum CenterItemType {
        /// An image with the given attributes.
        case image(ImageAttributes)

        /// A title, with an optional subtitle beneath it.
        case text(
            TextAttributes,
            subtitle: TextAttributes? = nil
        )
    }

    /// The type of button displayed on either side of the header.
    public enum PeripheralButtonType {
        /// An image button.
        case image(ImageButtonAttributes)

        /// A text button.
        case text(TextButtonAttributes)
    }

    /// The sizing behavior of the header.
    public enum SizeClass {
        /* MARK: Cases */

        /// A custom minimum height.
        case custom(minHeight: CGFloat)

        /// The standard height for full-screen cover presentations.
        case fullScreenCover

        /// The standard height for sheet presentations.
        case sheet

        /* MARK: Properties */

        var minHeight: CGFloat {
            switch self {
            case let .custom(
                minHeight: minHeight
            ): minHeight
            case .fullScreenCover: Floats.fullScreenCoverSizeClassFrameMinHeight
            case .sheet: Floats.sheetSizeClassFrameMinHeight
            }
        }
    }

    private enum PeripheralButtonAlignment {
        case left
        case right
    }

    // MARK: - Constants Accessors

    private typealias Colors = FoundationConstants.Colors.HeaderView
    private typealias Floats = FoundationConstants.CGFloats.HeaderView

    // MARK: - Dependencies

    @Dependency(\.uiApplication) private var uiApplication: UIApplication

    // MARK: - Properties

    let attributes: Attributes
    let centerItem: CenterItemType?
    let leftItem: PeripheralButtonType?
    let rightItem: PeripheralButtonType?

    // MARK: - Computed Properties

    private var imageMaxWidth: CGFloat { uiApplication.mainScreen.bounds.size.width / Floats.mainWindowSizeWidthDivisor }
    private var isThemed: Bool { attributes.appearance == .themed }

    // MARK: - Init

    init(
        leftItem: PeripheralButtonType? = nil,
        centerItem: CenterItemType? = nil,
        rightItem: PeripheralButtonType? = nil,
        attributes: Attributes = .init()
    ) {
        self.leftItem = leftItem
        self.centerItem = centerItem
        self.rightItem = rightItem
        self.attributes = attributes
    }

    // MARK: - Body

    public var body: some View {
        Group {
            if isThemed {
                VStack(spacing: 0) {
                    ThemedView {
                        contentView
                    }

                    dividerView
                }
            } else {
                VStack(spacing: 0) {
                    contentView
                    dividerView
                }
            }
        }
        .background(Color(uiColor: attributes.appearance.backgroundColor))
    }

    // MARK: - Content View

    private var contentView: some View {
        HStack {
            HStack {
                if let leftItem {
                    peripheralButton(for: leftItem, alignment: .left)
                }

                Spacer()
            }

            VStack {
                if let centerItem {
                    switch centerItem {
                    case let .image(imageAttributes):
                        centerImage(for: imageAttributes)

                    case let .text(titleAttributes, subtitle: subtitleAttributes):
                        centerText(for: titleAttributes)

                        if let subtitleAttributes {
                            centerText(for: subtitleAttributes)
                        }
                    }
                } else {
                    EmptyView()
                        .frame(alignment: .center)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            HStack {
                Spacer()

                if let rightItem {
                    peripheralButton(for: rightItem, alignment: .right)
                }
            }
        }
        .frame(minHeight: attributes.sizeClass.minHeight)
        .padding(.horizontal, Floats.horizontalPadding)
    }

    // MARK: - Center Image

    private func centerImage(for attributes: ImageAttributes) -> some View {
        attributes.image
            .renderingMode(.template)
            .resizable()
            .foregroundStyle(isThemed ? .navigationBarTitle : attributes.foregroundColor)
            .ifLet(attributes.size) { image, size in
                image
                    .frame(
                        width: size.width > imageMaxWidth ? nil : size.width,
                        height: size.height > Floats.imageMaxHeight ? nil : size.height
                    )
            } else: {
                $0.scaledToFit()
            }
            .frame(
                maxWidth: imageMaxWidth,
                maxHeight: Floats.imageMaxHeight,
                alignment: .center
            )
            .eraseToAnyView() // NIT: Carried over; unsure of efficacy as code compiles without this line.
    }

    // MARK: - Center Text

    private func centerText(for attributes: TextAttributes) -> some View {
        Text(attributes.string)
            .font(attributes.font)
            .foregroundStyle(isThemed ? .navigationBarTitle : attributes.foregroundColor)
            .lineLimit(
                attributes.string.count >= Int(Floats.longCenterItemTextCharacterCountThreshold) ? Int(Floats.longCenterItemTextLineLimit) : 1
            )
            .minimumScaleFactor(Floats.textMinimumScaleFactor)
            .multilineTextAlignment(.center)
    }

    // MARK: - Divider View

    @ViewBuilder
    private var dividerView: some View {
        if attributes.showsDivider {
            Rectangle()
                .frame(maxWidth: .infinity, maxHeight: Floats.separatorMaxHeight)
                .foregroundStyle(ThemeService.isDarkModeActive ? Colors.separatorDarkForeground : Colors.separatorLightForeground)
        }
    }

    // MARK: - Peripheral Button

    private func peripheralButton(
        for type: PeripheralButtonType,
        alignment: PeripheralButtonAlignment
    ) -> some View {
        Group {
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
                                    height: size.height > Floats.imageMaxHeight ? nil : size.height
                                )
                        }
                        .frame(
                            maxWidth: imageMaxWidth,
                            maxHeight: Floats.imageMaxHeight,
                            alignment: alignment == .left ? .leading : .trailing
                        )
                }
                .disabled(!attributes.isEnabled)

            case let .text(attributes):
                Button {
                    attributes.action()
                } label: {
                    Text(attributes.text.string)
                        .font(attributes.text.font)
                        .foregroundStyle(isThemed ? (attributes.isEnabled ? .accent : .disabled) : attributes.text.foregroundColor)
                        .lineLimit(1)
                        .minimumScaleFactor(Floats.textMinimumScaleFactor)
                }
                .disabled(!attributes.isEnabled)
            }
        }
    }
}
