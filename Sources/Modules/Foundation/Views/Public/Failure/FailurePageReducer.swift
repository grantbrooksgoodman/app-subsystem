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

public struct FailurePageReducer: Reducer {
    // MARK: - Dependencies

    @Dependency(\.alertKitConfig) private var alertKitConfig: AlertKit.Config
    @Dependency(\.build) private var build: Build

    // MARK: - Actions

    public enum Action {
        case executeRetryHandler
        case reportBugButtonTapped
    }

    // MARK: - State

    public struct State: Equatable {
        /* MARK: Properties */

        // String
        public var reportBugButtonText = AppSubsystem.delegates.localizedStrings.reportBug
        public var retryButtonText = AppSubsystem.delegates.localizedStrings.tryAgain

        // Other
        public var didReportBug = false
        public var exception: Exception
        public var retryHandler: (() -> Void)?

        /* MARK: Init */

        public init(
            _ exception: Exception,
            retryHandler: (() -> Void)? = nil
        ) {
            self.exception = exception
            self.retryHandler = retryHandler
        }

        /* MARK: Equatable Conformance */

        public static func == (left: State, right: State) -> Bool {
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

    public init() {}

    // MARK: - Reduce

    public func reduce(into state: inout State, action: Action) -> Effect<Action> {
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
