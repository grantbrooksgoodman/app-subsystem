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

public struct HeaderView: View {
    // MARK: - Types

    public enum Appearance: Equatable {
        /* MARK: Cases */

        case custom(backgroundColor: UIColor)
        case themed

        /* MARK: Properties */

        public var backgroundColor: UIColor {
            switch self {
            case let .custom(backgroundColor: backgroundColor):
                return backgroundColor

            case .themed:
                return .navigationBarBackground
            }
        }
    }

    public enum CenterItemType {
        case image(ImageAttributes)
        case text(TextAttributes, subtitle: TextAttributes? = nil)
    }

    public enum PeripheralButtonType {
        case image(ImageButtonAttributes)
        case text(TextButtonAttributes)
    }

    public enum SizeClass {
        /* MARK: Cases */

        case custom(minHeight: CGFloat)
        case fullScreenCover
        case sheet

        /* MARK: Properties */

        public var minHeight: CGFloat {
            switch self {
            case let .custom(minHeight: minHeight):
                return minHeight

            case .fullScreenCover:
                return Floats.fullScreenCoverSizeClassFrameMinHeight

            case .sheet:
                return Floats.sheetSizeClassFrameMinHeight
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

    public let attributes: Attributes
    public let centerItem: CenterItemType?
    public let leftItem: PeripheralButtonType?
    public let rightItem: PeripheralButtonType?

    // MARK: - Computed Properties

    private var imageMaxWidth: CGFloat { uiApplication.mainScreen.bounds.size.width / Floats.mainWindowSizeWidthDivisor }
    private var isThemed: Bool { attributes.appearance == .themed }

    // MARK: - Init

    public init(
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
