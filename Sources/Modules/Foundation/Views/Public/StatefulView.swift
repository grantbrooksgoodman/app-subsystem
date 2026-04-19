//
//  StatefulView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/// A container view that switches between loading, loaded, and error
/// states based on a bound ``ViewState`` value.
///
/// `StatefulView` eliminates the boilerplate of managing
/// loading indicators and failure screens by declaratively mapping a
/// single state binding to the appropriate presentation:
///
/// ```swift
/// @State private var viewState: StatefulView.ViewState = .loading
///
/// StatefulView($viewState, exceptionRetryHandler: { load() }) {
///     ContentView()
/// }
/// ```
///
/// When the state is ``ViewState/loading``, a full-screen progress
/// indicator is displayed. When the state transitions to
/// ``ViewState/loaded``, the content closure is rendered. If an error
/// occurs, set the state to ``ViewState/error(_:)`` with an
/// ``Exception`` to present a failure page with an optional retry
/// action.
///
/// State transitions animate with an opacity crossfade.
public struct StatefulView: View {
    // MARK: - Types

    /// The current state of a ``StatefulView``.
    public enum ViewState: Equatable {
        /// An error occurred. The associated ``Exception`` is
        /// displayed on a failure page.
        case error(Exception)

        /// Content has loaded and is ready for display.
        case loaded

        /// Content is loading. A progress indicator is shown.
        case loading
    }

    // MARK: - Properties

    private let content: () -> any View
    private let exceptionRetryHandler: (() -> Void)?
    private let progressPageViewBackgroundColor: Color

    @Binding private var viewState: ViewState

    // MARK: - Init

    /// Creates a stateful view driven by the given state binding.
    ///
    /// - Parameters:
    ///   - viewState: A binding to the current view state.
    ///   - exceptionRetryHandler: An optional closure executed when
    ///     the user taps the retry button on the failure page. Pass
    ///     `nil` to hide the retry button.
    ///   - progressPageViewBackgroundColor: The background color of
    ///     the progress indicator shown during the
    ///     ``ViewState/loading`` state. The default is
    ///     `Color.background`.
    ///   - content: The view to display when the state is
    ///     ``ViewState/loaded``.
    public init(
        _ viewState: Binding<ViewState>,
        exceptionRetryHandler: (() -> Void)? = nil,
        progressPageViewBackgroundColor: Color = .background,
        content: @escaping () -> any View
    ) {
        _viewState = viewState
        self.exceptionRetryHandler = exceptionRetryHandler
        self.progressPageViewBackgroundColor = progressPageViewBackgroundColor
        self.content = content
    }

    // MARK: - View

    public var body: some View {
        Group {
            switch viewState {
            case let .error(exception):
                FailurePageView(
                    .init(
                        initialState: .init(exception, retryHandler: exceptionRetryHandler),
                        reducer: FailurePageReducer()
                    )
                )

            case .loaded:
                content()
                    .eraseToAnyView()

            case .loading:
                ProgressPageView(backgroundColor: progressPageViewBackgroundColor)
            }
        }
        .transition(.opacity.animation(.easeIn(
            duration: FoundationConstants.CGFloats.ForcedUpdateModalPageView.transitionAnimationDuration
        )))
    }
}
