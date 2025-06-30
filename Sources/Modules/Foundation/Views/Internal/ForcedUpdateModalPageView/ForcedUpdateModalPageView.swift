//
//  ForcedUpdateModalPageView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import CoreImage
import Foundation
import SwiftUI

/* Proprietary */
import ComponentKit

struct ForcedUpdateModalPageView: View {
    // MARK: - Constants Accessors

    private typealias Colors = FoundationConstants.Colors.ForcedUpdateModalPageView
    private typealias Floats = FoundationConstants.CGFloats.ForcedUpdateModalPageView
    private typealias Strings = FoundationConstants.Strings.ForcedUpdateModalPageView

    // MARK: - Properties

    @StateObject private var viewModel: ViewModel<ForcedUpdateModalPageReducer>

    // MARK: - Init

    init(_ viewModel: ViewModel<ForcedUpdateModalPageReducer>) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    // MARK: - View

    var body: some View {
        StatefulView(viewModel.binding(for: \.viewState)) {
            VStack {
                Spacer()
                appIconImage
                ThemedView { callToActionContentView }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(
                .opacity.animation(
                    .easeIn(
                        duration: Floats.transitionAnimationDuration
                    )
                )
            )
        }
        .prefersStatusBarHidden()
        .onFirstAppear {
            viewModel.send(.viewAppeared)
        }
    }

    @ViewBuilder
    private var appIconImage: some View {
        if let appIconImage = viewModel.appIconImage {
            appIconImage
                .resizable()
                .cornerRadius(Floats.appIconImageCornerRadius)
                .frame(
                    maxWidth: Floats.appIconImageMaxWidth,
                    maxHeight: Floats.appIconImageMaxHeight
                )
                .overlay { appIconImageOverlay }
                .padding(.bottom, Floats.appIconImageBottomPadding)
        }
    }

    private var appIconImageOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Components.symbol(
                    Strings.appIconImageOverlaySymbolName,
                    foregroundColor: Colors.appIconImageOverlayForeground,
                    secondaryForegroundColor: Colors.appIconImageOverlaySecondaryForeground,
                    usesIntrinsicSize: false
                )
                .frame(
                    maxWidth: Floats.appIconImageOverlaySymbolFrameMaxWidth,
                    maxHeight: Floats.appIconImageOverlaySymbolFrameMaxHeight
                )
                .offset(
                    x: Floats.appIconImageOverlaySymbolXOffset,
                    y: Floats.appIconImageOverlaySymbolYOffset
                )
            }
        }
    }

    private var callToActionContentView: some View {
        Group {
            Components.text(
                viewModel.strings.value(for: .titleLabelText),
                font: .systemBold(scale: .large)
            )
            .padding(.bottom, Floats.titleLabelTextBottomPadding)
            .padding(.horizontal, Floats.titleLabelTextHorizontalPadding)

            Components.text(
                viewModel.strings.value(for: .subtitleLabelText),
                font: .system(scale: .custom(Floats.subtitleLabelTextSystemFontScale))
            )
            .multilineTextAlignment(.center)
            .padding(.bottom, Floats.subtitleLabelTextBottomPadding)
            .padding(.horizontal, Floats.subtitleLabelTextHorizontalPadding)

            if viewModel.shouldShowInstallButton {
                Components.capsuleButton(
                    viewModel.strings.value(for: .installButtonText),
                    font: .systemSemibold,
                    foregroundColor: Colors.installButtonTextForeground
                ) {
                    viewModel.send(.installButtonTapped)
                }
            }

            Spacer()

            Components.text(
                viewModel.versionLabelText,
                font: .system(scale: .small),
                foregroundColor: Colors.versionLabelTextForeground
            )
        }
    }
}

private extension Array where Element == TranslationOutputMap {
    func value(for key: TranslatedLabelStringCollection.ForcedUpdateModalPageViewStringKey) -> String {
        (first(where: { $0.key == .forcedUpdateModalPageView(key) })?.value ?? key.rawValue).sanitized
    }
}
