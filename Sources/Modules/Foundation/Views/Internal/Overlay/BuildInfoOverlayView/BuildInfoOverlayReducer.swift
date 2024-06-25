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
        case didShakeDevice
        case sendFeedbackButtonTapped

        case breadcrumbsDidCapture
        case isDeveloperModeEnabledChanged(Bool)
        case languageCodeChanged
        case shouldUseTranslucentAppearanceChanged(Bool)
    }

    // MARK: - Feedback

    enum Feedback {
        case restoreIndicatorColor
    }

    // MARK: - State

    struct State: Equatable {
        /* MARK: Properties */

        // Bool
        var isDeveloperModeEnabled = false
        var shouldUseTranslucentAppearance = false

        // String
        var buildInfoButtonText = ""
        var sendFeedbackButtonText = AppSubsystem.delegates.localizedStrings.sendFeedback

        // Other
        var developerModeIndicatorDotColor: Color = AppSubsystem.delegates.buildInfoOverlayDotIndicatorColor.developerModeIndicatorDotColor
        var yOffset: CGFloat

        /* MARK: Init */

        init(_ yOffset: CGFloat = 0) {
            self.yOffset = yOffset
        }
    }

    // MARK: - Init

    init() {}

    // MARK: - Reduce

    func reduce(into state: inout State, for event: Event) -> Effect<Feedback> {
        switch event {
        case .action(.viewAppeared): // swiftlint:disable:next line_length
            state.buildInfoButtonText = "\(build.codeName) \(build.bundleVersion) (\(String(build.buildNumber))\(build.milestone.shortString)/\(build.bundleRevision.lowercased()))"

            @Persistent(.developerModeEnabled) var defaultsValue: Bool?
            guard let defaultsValue else { return .none }
            state.isDeveloperModeEnabled = defaultsValue

        case .action(.buildInfoButtonTapped):
            viewService.buildInfoButtonTapped()

        case .action(.didShakeDevice):
            guard build.developerModeEnabled else { return .none }
            DevModeService.presentActionSheet()

        case .action(.breadcrumbsDidCapture):
            state.developerModeIndicatorDotColor = .red
            return .task(delay: .seconds(1.5)) {
                .restoreIndicatorColor
            }

        case let .action(.isDeveloperModeEnabledChanged(developerModeEnabled)):
            state.isDeveloperModeEnabled = developerModeEnabled

        case .action(.languageCodeChanged):
            state.sendFeedbackButtonText = AppSubsystem.delegates.localizedStrings.sendFeedback

        case .action(.sendFeedbackButtonTapped):
            viewService.sendFeedbackButtonTapped()

        case let .action(.shouldUseTranslucentAppearanceChanged(shouldUseTranslucentAppearance)):
            state.shouldUseTranslucentAppearance = shouldUseTranslucentAppearance

        case .feedback(.restoreIndicatorColor):
            state.developerModeIndicatorDotColor = AppSubsystem.delegates.buildInfoOverlayDotIndicatorColor.developerModeIndicatorDotColor
        }

        return .none
    }
}
