//
//  RootWindowReducer.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

struct RootWindowReducer: Reducer {
    // MARK: - Dependencies

    @Dependency(\.rootWindowService) private var rootWindowService: RootWindowService

    // MARK: - Actions

    enum Action {
        case viewAppeared
        case isBuildInfoOverlayHiddenChanged(Bool)
    }

    // MARK: - Feedback

    typealias Feedback = Never

    // MARK: - State

    struct State: Equatable {
        /* MARK: Properties */

        var isBuildInfoOverlayHidden = Observables.isBuildInfoOverlayHidden.value
    }

    // MARK: - Init

    init() {}

    // MARK: - Reduce

    func reduce(into state: inout State, for event: Event) -> Effect<Feedback> {
        switch event {
        case .action(.viewAppeared):
            rootWindowService.startRaisingWindow()

        case let .action(.isBuildInfoOverlayHiddenChanged(isBuildInfoOverlayHidden)):
            state.isBuildInfoOverlayHidden = isBuildInfoOverlayHidden
        }

        return .none
    }
}
