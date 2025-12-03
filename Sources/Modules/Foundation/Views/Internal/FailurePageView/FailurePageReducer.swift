//
//  FailurePageReducer.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/* Proprietary */
import AlertKit

struct FailurePageReducer: Reducer {
    // MARK: - Dependencies

    @Dependency(\.alertKitConfig) private var alertKitConfig: AlertKit.Config
    @Dependency(\.build) private var build: Build

    // MARK: - Actions

    enum Action {
        case executeRetryHandler
        case reportBugButtonTapped
    }

    // MARK: - State

    struct State: Equatable {
        /* MARK: Properties */

        var didReportBug = false
        var exception: Exception
        var reportBugButtonText = AppSubsystem.delegates.localizedStrings.reportBug
        var retryButtonText = AppSubsystem.delegates.localizedStrings.tryAgain
        var retryHandler: (() -> Void)?

        /* MARK: Init */

        init(
            _ exception: Exception,
            retryHandler: (() -> Void)? = nil
        ) {
            self.exception = exception
            self.retryHandler = retryHandler
        }

        /* MARK: Equatable Conformance */

        static func == (left: State, right: State) -> Bool {
            let bothNilRetryHandlers = left.retryHandler == nil && right.retryHandler == nil
            let sameDidReportBug = left.didReportBug == right.didReportBug
            let sameException = left.exception == right.exception
            let sameReportBugButtonText = left.reportBugButtonText == right.reportBugButtonText
            let sameRetryButtonText = left.retryButtonText == right.retryButtonText

            guard bothNilRetryHandlers,
                  sameDidReportBug,
                  sameException,
                  sameReportBugButtonText,
                  sameRetryButtonText else { return false }

            return true
        }
    }

    // MARK: - Init

    init() {}

    // MARK: - Reduce

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .executeRetryHandler:
            guard let effect = state.retryHandler else { return .none }
            effect()

        case .reportBugButtonTapped:
            guard build.isOnline else {
                Task { await ConnectionAlert.present() }
                return .none
            }

            alertKitConfig.reportDelegate?.fileReport(state.exception)
            state.didReportBug = true
        }

        return .none
    }
}
