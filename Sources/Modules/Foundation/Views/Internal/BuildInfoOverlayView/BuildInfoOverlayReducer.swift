//
//  BuildInfoOverlayReducer.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

struct BuildInfoOverlayReducer: Reducer {
    // MARK: - Dependencies

    @Dependency(\.build) private var build: Build
    @Dependency(\.buildInfoOverlayViewService) private var viewService: BuildInfoOverlayViewService

    // MARK: - Actions

    enum Action {
        case viewAppeared

        case buildInfoButtonTapped
        case sendFeedbackButtonTapped

        case breadcrumbsDidCapture
        case restoreIndicatorColor
        case shouldUseTranslucentAppearanceChanged(Bool)
        case updateStatsLabelText
    }

    // MARK: - State

    struct State: Equatable {
        /* MARK: Properties */

        var buildInfoButtonText = ""
        var developerModeIndicatorDotColor: Color = AppSubsystem.delegates.buildInfoOverlayDotIndicatorColor?.developerModeIndicatorDotColor ?? .orange
        var shouldUseTranslucentAppearance = false
        var statsLabelText = "Calculating..."
        var yOffset: CGFloat

        /* MARK: Computed Properties */

        var backgroundColor: Color { .black.opacity(shouldUseTranslucentAppearance ? 0.35 : 1) }
        var isDeveloperModeEnabled: Bool { Dependency(\.build.isDeveloperModeEnabled).wrappedValue }
        var isUserInteractionDisabled: Bool {
            Dependency(\.uiApplication.isPresentingAlertController).wrappedValue || RootWindowStatus.shared.rootView == .expiryPage
        }

        var sendFeedbackButtonText: String { AppSubsystem.delegates.localizedStrings.sendFeedback } // swiftlint:disable:next identifier_name

        fileprivate var _statsLabelText: String {
            @Dependency(\.coreKit.utils.appMemoryFootprint) var appMemoryFootprint: Int?
            @Dependency(\.uiApplication.presentedViews.count) var presentedViewsCount: Int
            return "\(presentedViewsCount) views // \(appMemoryFootprint ?? 0)MB in use"
        }

        /* MARK: Init */

        init(_ yOffset: CGFloat = 0) {
            self.yOffset = yOffset
        }
    }

    // MARK: - Init

    init() {}

    // MARK: - Reduce

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .viewAppeared: // swiftlint:disable:next line_length
            state.buildInfoButtonText = "\(build.codeName) \(build.bundleVersion) (\(String(build.buildNumber))\(build.milestone.shortString)/\(build.bundleRevision.lowercased()))"
            return .task(priority: .background) {
                .updateStatsLabelText
            }

        case .buildInfoButtonTapped:
            viewService.buildInfoButtonTapped()

        case .breadcrumbsDidCapture:
            state.developerModeIndicatorDotColor = .red
            return .task(delay: .seconds(1.5)) {
                .restoreIndicatorColor
            }

        case .restoreIndicatorColor:
            state.developerModeIndicatorDotColor = AppSubsystem.delegates.buildInfoOverlayDotIndicatorColor?.developerModeIndicatorDotColor ?? .orange

        case .sendFeedbackButtonTapped:
            viewService.sendFeedbackButtonTapped()

        case let .shouldUseTranslucentAppearanceChanged(shouldUseTranslucentAppearance):
            state.shouldUseTranslucentAppearance = shouldUseTranslucentAppearance

        case .updateStatsLabelText:
            state.statsLabelText = state._statsLabelText
            return .task(priority: .background, delay: .seconds(1)) {
                .updateStatsLabelText
            }
        }

        return .none
    }
}
