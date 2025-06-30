//
//  StatefulView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

public struct StatefulView: View {
    // MARK: - Types

    public enum ViewState: Equatable {
        case error(Exception)
        case loaded
        case loading
    }

    // MARK: - Properties

    private let content: () -> any View
    private let exceptionRetryHandler: (() -> Void)?
    private let progressPageViewBackgroundColor: Color

    @Binding private var viewState: ViewState

    // MARK: - Init

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
        .transition(.opacity.animation(.easeIn(duration: 0.2)))
    }
}
