//
//  ToastView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/* Proprietary */
import ComponentKit

struct ToastView: View {
    // MARK: - Constants Accessors

    private typealias Colors = FoundationConstants.Colors.ToastView
    private typealias Floats = FoundationConstants.CGFloats.ToastView
    private typealias Strings = FoundationConstants.Strings.ToastView

    // MARK: - Dependencies

    @Dependency(\.uiSelectionFeedbackGenerator) private var uiSelectionFeedbackGenerator: UISelectionFeedbackGenerator

    // MARK: - Properties

    private let message: String
    private let onDismiss: () -> Void
    private let onTap: (() -> Void)?
    private let title: String?
    private let type: Toast.ToastType

    // MARK: - Computed Properties

    private var accentColor: Color? { (Toast.overrideColorPalette ?? type.colorPalette)?.accent ?? type.style.defaultColor }

    // MARK: - Init

    init(
        _ type: Toast.ToastType,
        title: String? = nil,
        message: String,
        onTap: (() -> Void)?,
        onDismiss: @escaping () -> Void
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.onTap = onTap
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    var body: some View {
        switch type {
        case let .banner(style: style, appearanceEdge: _, colorPalette: colorPalette, showsDismissButton: showsDismissButton):
            bannerContentView(
                style: style,
                colorPalette: Toast.overrideColorPalette ?? colorPalette,
                showsDismissButton: showsDismissButton
            )

        case let .capsule(style: style):
            capsuleContentView(style: style)
        }
    }

    // MARK: - Banner Content View

    private func bannerContentView(
        style: Toast.Style,
        colorPalette: Toast.ColorPalette?,
        showsDismissButton: Bool
    ) -> some View {
        VStack(alignment: .leading) {
            HStack(alignment: title == nil ? .center : .top) {
                if let iconSystemImageName = style.bannerIconSystemImageName,
                   let accentColor {
                    Components.symbol(
                        iconSystemImageName,
                        foregroundColor: accentColor,
                        usesIntrinsicSize: true
                    )
                }

                let labelView = VStack(alignment: .leading) {
                    if let title {
                        Components.text(
                            title,
                            font: .init(
                                .system(style: .semibold()),
                                scale: .custom(Floats.bannerTitleLabelFontSize)
                            ),
                            foregroundColor: colorPalette?.text ?? .titleText.opacity(Floats.bannerTitleLabelForegroundColorOpacity)
                        )
                        .multilineTextAlignment(.leading)
                    }

                    Components.text(
                        message,
                        font: .init(
                            .system(style: title == nil ? .semibold() : .regular()),
                            scale: .custom(Floats.bannerMessageLabelFontSize)
                        ),
                        foregroundColor: colorPalette?.text ?? .titleText.opacity(Floats.bannerMessageLabelForegroundColorOpacity)
                    )
                    .multilineTextAlignment(.leading)
                }

                if let onTap {
                    Button {
                        vibrate()
                        onTap()
                        onDismiss()
                    } label: {
                        labelView
                    }
                } else {
                    labelView
                }

                Spacer(minLength: Floats.bannerSpacerMinLength)

                if showsDismissButton {
                    Components.button(
                        symbolName: Strings.bannerDismissButtonImageSystemName,
                        foregroundColor: colorPalette?.dismissButton ?? .titleText.opacity(Floats.bannerDismissButtonForegroundColorOpacity)
                    ) {
                        onDismiss()
                    }
                }
            }
            .padding()
        }
        .background(colorPalette?.background ?? .navigationBarBackground)
        .frame(maxWidth: .infinity)
        .ifLet(accentColor) { bannerContentView, accentColor in
            bannerContentView
                .overlay(
                    overlay(accentColor),
                    alignment: .leading,
                )
        }
        .cornerRadius(Floats.bannerCornerRadius)
        .shadow(
            color: Colors.bannerShadowColor.opacity(Floats.bannerShadowColorOpacity),
            radius: Floats.bannerShadowRadius,
            x: Floats.bannerShadowX,
            y: Floats.bannerShadowY
        )
        .padding(.horizontal, Floats.bannerHorizontalPadding)
    }

    // MARK: - Capsule Content View

    private func capsuleContentView(style: Toast.Style) -> some View {
        VStack {
            let labelView = HStack {
                if let iconSystemImageName = style.capsuleIconSystemImageName,
                   let defaultColor = style.defaultColor {
                    Components.symbol(
                        iconSystemImageName,
                        foregroundColor: defaultColor,
                        usesIntrinsicSize: false
                    )
                    .frame(
                        maxWidth: Floats.capsuleImageFrameMaxWidth,
                        maxHeight: Floats.capsuleImageFrameMaxHeight,
                        alignment: .center
                    )
                }

                if let title {
                    VStack(alignment: style.capsuleIconSystemImageName == nil ? .center : .leading) {
                        Components.text(
                            title,
                            font: .systemSemibold(scale: .custom(Floats.capsuleTitleLabelFontSize)),
                            foregroundColor: .titleText
                        )
                        .multilineTextAlignment(.leading)

                        Components.text(
                            message,
                            font: .system(scale: .custom(Floats.capsuleMessageLabelFontSize)),
                            foregroundColor: Colors.capsuleMessageLabelForeground
                        )
                        .multilineTextAlignment(.leading)
                    }
                } else {
                    Components.text(
                        message,
                        font: .systemSemibold(scale: .custom(Floats.capsuleTitleLabelFontSize)),
                        foregroundColor: .titleText
                    )
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, Floats.capsuleMessageLabelHorizontalPadding)
                    .padding(.vertical, Floats.capsuleMessageLabelVerticalPadding)
                }
            }

            if let onTap {
                Button {
                    vibrate()
                    onTap()
                    onDismiss()
                } label: {
                    labelView
                }
            } else {
                labelView
                    .onTapGesture {
                        onDismiss()
                    }
            }
        }
        .padding(.horizontal, Floats.capsulePrimaryHorizontalPadding)
        .padding(.vertical, Floats.capsuleVerticalPadding)
        .background(Color.navigationBarBackground)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    Colors.capsuleOverlayStroke.opacity(Floats.capsuleOverlayStrokeColorOpacity),
                    lineWidth: Floats.capsuleOverlayStrokeLineWidth
                )
        )
        .frame(maxWidth: .infinity)
        .shadow(
            color: Colors.capsuleShadowColor.opacity(Floats.capsuleShadowColorOpacity),
            radius: Floats.capsuleShadowRadius,
            x: Floats.capsuleShadowX,
            y: Floats.capsuleShadowY
        )
        .padding(.horizontal, Floats.capsuleSecondaryHorizontalPadding)
    }

    // MARK: - Overlay

    private func overlay(_ fillColor: Color) -> some View {
        Rectangle()
            .fill(fillColor)
            .frame(width: Floats.bannerOverlayFrameWidth)
            .clipped(antialiased: true)
    }

    // MARK: - Auxiliary

    private func vibrate() {
        uiSelectionFeedbackGenerator.selectionChanged()
    }
}

/* MARK: UISelectionFeedbackGenerator Dependency */

private enum UISelectionFeedbackGeneratorDependency: DependencyKey {
    static func resolve(_: DependencyValues) -> UISelectionFeedbackGenerator {
        .init()
    }
}

private extension DependencyValues {
    var uiSelectionFeedbackGenerator: UISelectionFeedbackGenerator {
        get { self[UISelectionFeedbackGeneratorDependency.self] }
        set { self[UISelectionFeedbackGeneratorDependency.self] = newValue }
    }
}
