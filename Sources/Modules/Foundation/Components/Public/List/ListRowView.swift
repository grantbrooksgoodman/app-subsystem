//
//  ListRowView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/* Proprietary */
import ComponentKit

public struct ListRowView: View {
    // MARK: - Constants Accessors

    private typealias Colors = FoundationConstants.Colors.ListRowView
    private typealias Floats = FoundationConstants.CGFloats.ListRowView
    private typealias Strings = FoundationConstants.Strings.ListRowView

    // MARK: - Properties

    private let configuration: Configuration
    private let image: Image?

    // MARK: - Init

    public init(_ configuration: Configuration) {
        self.configuration = configuration

        if let imageView = configuration.imageView?() {
            image = ImageRenderer(content: imageView.eraseToAnyView()).uiImage.swiftUIImage
        } else {
            image = nil
        }
    }

    // MARK: - View

    public var body: some View {
        if configuration.headerText != nil || configuration.footerText != nil {
            VStack(alignment: .leading) {
                if let headerText = configuration.headerText {
                    Components.text(
                        headerText.uppercased(),
                        font: .system(scale: .custom(Floats.headerLabelSystemFontScale)),
                        foregroundColor: .subtitleText
                    )
                    .padding(.bottom, -1)
                    .padding(.horizontal, Floats.headerLabelHorizontalPadding)
                }

                contentView
                    .clipShape(RoundedRectangle(cornerRadius: configuration.cornerRadius))
                    .disabled(!configuration.isEnabled)

                if let footerText = configuration.footerText {
                    Components.text(
                        footerText,
                        font: .system(scale: .custom(Floats.footerLabelSystemFontScale)),
                        foregroundColor: .subtitleText
                    )
                    .padding(.horizontal, Floats.footerLabelHorizontalPadding)
                    .padding(.top, 1)
                }
            }
        } else {
            contentView
                .clipShape(RoundedRectangle(cornerRadius: configuration.cornerRadius))
                .disabled(!configuration.isEnabled)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch configuration.interaction {
        case .button:
            Button {
                configuration.interaction.buttonAction?()
            } label: {
                labelView
            }
            .buttonStyle(ListRowButtonStyle())

        case let .destination(_, view):
            NavigationLink {
                view.eraseToAnyView()
            } label: {
                labelView
            }
            .buttonStyle(ListRowButtonStyle())

        case .switch:
            labelView
                .background(ThemeService.isDarkModeActive ? Colors.darkBackground : Colors.lightBackground)
        }
    }

    private var labelView: some View {
        HStack {
            if let image {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: Floats.imageFrameWidth,
                        height: Floats.imageFrameHeight
                    )
                    .padding(.leading, Floats.imageLeadingPadding)
            }

            Components.text(
                configuration.innerText,
                foregroundColor: configuration.isEnabled ? configuration.innerTextColor : Colors.titleLabelDisabledForeground,
                isInspectable: configuration.isInspectable
            )
            .padding(.leading, image == nil ? 0 : Floats.titleLabelLeadingPadding)

            Spacer()

            if let isSwitchToggled = configuration.interaction.isSwitchToggled {
                Toggle("", isOn: isSwitchToggled)
                    .labelsHidden()
            } else if configuration.interaction.buttonShowsChevron == true || configuration.interaction.destination != nil {
                Components.symbol(
                    Strings.chevronImageSystemName,
                    foregroundColor: .init(
                        uiColor: configuration.isEnabled ? ((
                            ThemeService.isDarkModeActive ? .subtitleText : .subtitleText.lighter()
                        ) ?? .subtitleText) : .disabled
                    ),
                    weight: .semibold,
                    usesIntrinsicSize: false
                )
                .frame(
                    maxWidth: Floats.chevronImageFrameMaxWidth,
                    maxHeight: Floats.chevronImageFrameMaxHeight
                )
            }
        }
        .padding(.horizontal)
        .padding(.vertical, Floats.verticalPadding)
        .frame(minHeight: Floats.frameMinHeight)
    }
}

private struct ListRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        typealias Colors = FoundationConstants.Colors.ListRowView
        return configuration.label
            .background(
                configuration.isPressed ? (
                    ThemeService.isDarkModeActive ? Colors.buttonStyleDarkPressedBackground : Colors.buttonStyleLightPressedBackground
                ) : ThemeService.isDarkModeActive ? Colors.buttonStyleDarkNotPressedBackground : Colors.buttonStyleLightNotPressedBackground
            )
    }
}
