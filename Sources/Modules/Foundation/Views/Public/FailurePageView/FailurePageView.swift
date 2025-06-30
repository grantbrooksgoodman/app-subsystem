//
//  FailurePageView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/* Proprietary */
import ComponentKit

public struct FailurePageView: View {
    // MARK: - Constants Accessors

    private typealias Colors = FoundationConstants.Colors.FailureView
    private typealias Floats = FoundationConstants.CGFloats.FailureView
    private typealias Strings = FoundationConstants.Strings.FailureView

    // MARK: - Properties

    @StateObject private var viewModel: ViewModel<FailurePageReducer>

    // MARK: - Init

    public init(_ viewModel: ViewModel<FailurePageReducer>) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    // MARK: - View

    public var body: some View {
        ThemedView {
            VStack {
                Components.symbol(
                    Strings.imageSystemName,
                    foregroundColor: Colors.imageForegroundColor,
                    usesIntrinsicSize: false
                )
                .frame(
                    maxWidth: Floats.imageFrameMaxWidth,
                    maxHeight: Floats.imageFrameMaxHeight
                )
                .padding(.bottom, Floats.imageBottomPadding)

                Components.text(
                    viewModel.exception.userFacingDescriptor,
                    font: .systemSemibold(scale: .custom(Floats.exceptionLabelFontSize))
                )
                .multilineTextAlignment(.center)
                .padding(.bottom, Floats.exceptionLabelBottomPadding)
                .padding(.horizontal, Floats.exceptionLabelHorizontalPadding)

                if viewModel.retryHandler != nil {
                    retryButton
                }

                if viewModel.exception.isReportable {
                    reportBugButton
                }
            }
        }
    }

    @ViewBuilder
    private var reportBugButton: some View {
        let action: () -> Void = { viewModel.send(.reportBugButtonTapped) }
        let font: ComponentKit.Font = .system(scale: .custom(Floats.retryButtonLabelFontSize))
        let text = viewModel.reportBugButtonText

        Group {
            if viewModel.retryHandler == nil {
                Components.capsuleButton(
                    text,
                    font: font,
                    foregroundColor: viewModel.didReportBug ? .disabled : .background
                ) { action() }
            } else {
                Components.button(
                    text,
                    font: font,
                    foregroundColor: viewModel.didReportBug ? .disabled : .accent
                ) { action() }
            }
        }
        .disabled(viewModel.didReportBug)
    }

    @ViewBuilder
    private var retryButton: some View {
        let action: () -> Void = { viewModel.send(.executeRetryHandler) }
        let font: ComponentKit.Font = .systemSemibold
        let text = viewModel.retryButtonText

        Group {
            if viewModel.exception.isReportable {
                Components.capsuleButton(
                    text,
                    font: font,
                    foregroundColor: .background
                ) { action() }
            } else {
                Components.button(
                    text,
                    font: font
                ) { action() }
            }
        }
        .padding(.bottom, Floats.retryButtonBottomPadding)
    }
}
