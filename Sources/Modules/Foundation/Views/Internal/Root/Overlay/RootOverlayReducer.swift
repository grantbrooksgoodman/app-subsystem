//
//  RootOverlayReducer.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

struct RootOverlayReducer: Reducer {
    // MARK: - Dependencies

    @Dependency(\.rootWindowService) private var rootWindowService: RootWindowService

    // MARK: - Actions

    enum Action {
        case viewAppeared

        case isPresentingSheetChanged(Bool)
        case sheetChanged(AnyView?)
        case toastActionChanged((() -> Void)?)
        case toastChanged(Toast?)
    }

    // MARK: - Feedback

    typealias Feedback = Never

    // MARK: - State

    struct State: Equatable {
        /* MARK: Properties */

        var isPresentingSheet = false
        var sheet: AnyView = .init(EmptyView())
        var toast: Toast?
        var toastAction: (() -> Void)?

        /* MARK: Init */

        init() {}

        /* MARK: Equatable Conformance */

        static func == (left: State, right: State) -> Bool {
            let sameIsPresentingSheet = left.isPresentingSheet == right.isPresentingSheet
            let sameToast = left.toast == right.toast
            let sameToastAction = left.toastAction.debugDescription == right.toastAction.debugDescription

            guard sameIsPresentingSheet,
                  sameToast,
                  sameToastAction else { return false }
            return true
        }
    }

    // MARK: - Init

    init() {}

    // MARK: - Reduce

    func reduce(into state: inout State, for event: Event) -> Effect<Feedback> {
        switch event {
        case .action(.viewAppeared):
            guard UIApplication.iOS19IsAvailable else { return .none }
            rootWindowService.addKeyboardAppearanceObservers()

        case let .action(.isPresentingSheetChanged(isPresentingSheet)):
            state.isPresentingSheet = isPresentingSheet

        case let .action(.sheetChanged(sheet)):
            state.sheet = sheet ?? .init(EmptyView())
            state.isPresentingSheet = sheet != nil

        case let .action(.toastActionChanged(action)):
            state.toastAction = action

        case let .action(.toastChanged(toast)):
            state.toast = toast
            state.toastAction = nil
        }

        return .none
    }
}
