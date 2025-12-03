//
//  ThemedReducer.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

struct ThemedReducer: Reducer {
    // MARK: - Actions

    enum Action {
        case viewAppeared
        case viewDisappeared
        case appearanceChanged
    }

    // MARK: - State

    struct State: Equatable {
        /* MARK: Properties */

        var body: () -> any View
        var viewID = UUID()

        fileprivate var navigationBarAppearance: NavigationBarAppearance?
        fileprivate var objectID = UUID()
        fileprivate var previousNavigationBarAppearance: NavigationBarAppearance?
        fileprivate var redrawsOnAppearanceChange: Bool // swiftlint:disable:next identifier_name
        fileprivate var restoresNavigationBarAppearanceOnDisappear: Bool

        /* MARK: Init */

        init(
            _ body: @escaping (() -> any View),
            navigationBarAppearance: NavigationBarAppearance?,
            redrawsOnAppearanceChange: Bool, // swiftlint:disable:next identifier_name
            restoresNavigationBarAppearanceOnDisappear: Bool
        ) {
            self.body = body
            self.navigationBarAppearance = navigationBarAppearance
            self.redrawsOnAppearanceChange = redrawsOnAppearanceChange
            self.restoresNavigationBarAppearanceOnDisappear = restoresNavigationBarAppearanceOnDisappear
        }

        /* MARK: Equatable Conformance */

        static func == (left: ThemedReducer.State, right: ThemedReducer.State) -> Bool {
            let sameNavigationBarAppearance = left.navigationBarAppearance == right.navigationBarAppearance
            let samePreviousNavigationBarAppearance = left.previousNavigationBarAppearance == right.previousNavigationBarAppearance
            let sameObjectID = left.objectID == right.objectID
            let sameRedrawsOnAppearanceChange = left.redrawsOnAppearanceChange == right.redrawsOnAppearanceChange
            // swiftlint:disable:next identifier_name line_length
            let sameRestoresNavigationBarAppearanceOnDisappear = left.restoresNavigationBarAppearanceOnDisappear == right.restoresNavigationBarAppearanceOnDisappear
            let sameViewID = left.viewID == right.viewID

            guard sameNavigationBarAppearance,
                  samePreviousNavigationBarAppearance,
                  sameObjectID,
                  sameRedrawsOnAppearanceChange,
                  sameRestoresNavigationBarAppearanceOnDisappear,
                  sameViewID else {
                return false
            }

            return true
        }
    }

    // MARK: - Reduce

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .viewAppeared:
            state.previousNavigationBarAppearance = NavigationBar.currentAppearance
            guard let navigationBarAppearance = state.navigationBarAppearance else { return .none }
            NavigationBar.setAppearance(navigationBarAppearance)

        case .viewDisappeared:
            guard state.restoresNavigationBarAppearanceOnDisappear,
                  state.navigationBarAppearance != nil,
                  let previousNavigationBarAppearance = state.previousNavigationBarAppearance else { return .none }
            NavigationBar.setAppearance(previousNavigationBarAppearance)

        case .appearanceChanged:
            if let navigationBarAppearance = state.navigationBarAppearance {
                NavigationBar.setAppearance(navigationBarAppearance)
            }

            state.objectID = UUID()
            guard state.redrawsOnAppearanceChange else { return .none }
            state.viewID = UUID()
        }

        return .none
    }
}
