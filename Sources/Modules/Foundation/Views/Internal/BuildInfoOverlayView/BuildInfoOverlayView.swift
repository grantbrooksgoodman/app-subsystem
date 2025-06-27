//
//  BuildInfoOverlayView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/* Proprietary */
import ComponentKit

struct BuildInfoOverlayView: View {
    // MARK: - Constants Accessors

    private typealias Colors = FoundationConstants.Colors.BuildInfoOverlayView
    private typealias Floats = FoundationConstants.CGFloats.BuildInfoOverlayView
    private typealias Strings = FoundationConstants.Strings.BuildInfoOverlayView

    // MARK: - Properties

    @StateObject private var viewModel: ViewModel<BuildInfoOverlayReducer>
    @StateObject private var observer: ViewObserver<BuildInfoOverlayViewObserver>

    // MARK: - Init

    init(_ viewModel: ViewModel<BuildInfoOverlayReducer>) {
        _viewModel = .init(wrappedValue: viewModel)
        _observer = .init(wrappedValue: .init(.init(viewModel)))
    }

    // MARK: - View

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            sendFeedbackButton
            statsView
            buildInfoButton
        }
        .if(UIApplication.iOS26IsAvailable && !UIApplication.iOS27IsAvailable) {
            $0
                .fixedSize()
                .background { TouchProxy() }
        }
        .animation(
            .easeIn.speed(Floats.translucencyAnimationSpeed),
            value: viewModel.shouldUseTranslucentAppearance
        )
        .offset(x: Floats.xOffset, y: viewModel.yOffset)
        .onFirstAppear {
            viewModel.send(.viewAppeared)
        }
    }

    private var buildInfoButton: some View {
        Button {
            viewModel.send(.buildInfoButtonTapped)
        } label: {
            if viewModel.isDeveloperModeEnabled {
                Circle()
                    .foregroundStyle(viewModel.developerModeIndicatorDotColor)
                    .frame(
                        width: Floats.developerModeIndicatorFrameWidth,
                        height: Floats.developerModeIndicatorFrameHeight,
                        alignment: .trailing
                    )
                    .padding(.trailing, Floats.developerModeIndicatorTrailingPadding)
            }

            Components.text(
                viewModel.buildInfoButtonText,
                font: .systemBold(scale: .small),
                foregroundColor: Colors.buildInfoButtonLabelForeground
            )
        }
        .disabled(viewModel.isUserInteractionDisabled)
        .frame(height: Floats.buildInfoButtonFrameHeight)
        .padding(.horizontal, 1)
        .background(viewModel.backgroundColor)
    }

    private var sendFeedbackButton: some View {
        Components.button(
            viewModel.sendFeedbackButtonText,
            font: .init(
                .custom(
                    name: Strings.sendFeedbackButtonLabelFontName,
                    isUnderlined: true
                ),
                scale: .custom(Floats.sendFeedbackButtonLabelFontSize)
            ),
            foregroundColor: Colors.sendFeedbackButtonLabelForeground
        ) {
            viewModel.send(.sendFeedbackButtonTapped)
        }
        .disabled(viewModel.isUserInteractionDisabled)
        .frame(height: Floats.sendFeedbackButtonFrameHeight)
        .padding(.horizontal, 1)
        .background(viewModel.backgroundColor)
    }

    private var statsView: some View {
        Components.text(
            viewModel.statsLabelText,
            font: .system(scale: .small),
            foregroundColor: Colors.statsLabelForeground
        )
        .frame(height: Floats.statsViewFrameHeight)
        .padding(.horizontal, 1)
        .background(viewModel.backgroundColor)
    }
}
