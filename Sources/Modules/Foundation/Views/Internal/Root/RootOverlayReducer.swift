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

    @Dependency(\.build) private var build: Build
    @Dependency(\.rootWindowService) private var rootWindowService: RootWindowService

    // MARK: - Actions

    enum Action {
        case viewAppeared

        case didShakeDevice
        case isBuildInfoOverlayHiddenChanged(Bool)
        case isPresentingSheetChanged(Bool)
        case sheetChanged(AnyView?)
        case toastActionChanged((() -> Void)?)
        case toastChanged(Toast?)
    }

    // MARK: - State

    struct State: Equatable {
        /* MARK: Properties */

        var isBuildInfoOverlayHidden = Observables.isBuildInfoOverlayHidden.value
        var isPresentingSheet = false
        var sheet: AnyView = .init(EmptyView())
        var toast: Toast?
        var toastAction: (() -> Void)?

        /* MARK: Computed Properties */

        var buildInfoOverlayYOffset: CGFloat {
            @Dependency(\.uiApplication.mainWindow?.safeAreaInsets.bottom) var safeAreaBottomInsets: CGFloat?
            return (safeAreaBottomInsets ?? 0) == 0 ? 10 : 30
        }

        /* MARK: Init */

        init() {}

        /* MARK: Equatable Conformance */

        static func == (left: State, right: State) -> Bool {
            let sameIsBuildInfoOverlayHidden = left.isBuildInfoOverlayHidden == right.isBuildInfoOverlayHidden
            let sameIsPresentingSheet = left.isPresentingSheet == right.isPresentingSheet
            let sameToast = left.toast == right.toast
            let sameToastAction = left.toastAction.debugDescription == right.toastAction.debugDescription

            guard sameIsBuildInfoOverlayHidden,
                  sameIsPresentingSheet,
                  sameToast,
                  sameToastAction else { return false }
            return true
        }
    }

    // MARK: - Init

    init() {}

    // MARK: - Reduce

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .viewAppeared:
            rootWindowService.startRaisingWindow()
            guard UIApplication.iOS27IsAvailable else { return .none }
            rootWindowService.addKeyboardAppearanceObservers()

        case .didShakeDevice:
            guard build.isDeveloperModeEnabled else { return .none }
            DevModeService.presentActionSheet()

        case let .isBuildInfoOverlayHiddenChanged(isBuildInfoOverlayHidden):
            state.isBuildInfoOverlayHidden = isBuildInfoOverlayHidden

        case let .isPresentingSheetChanged(isPresentingSheet):
            state.isPresentingSheet = isPresentingSheet

        case let .sheetChanged(sheet):
            state.sheet = sheet ?? .init(EmptyView())
            state.isPresentingSheet = sheet != nil

        case let .toastActionChanged(action):
            state.toastAction = action

        case let .toastChanged(toast):
            state.toast = toast
            state.toastAction = nil
        }

        return .none
    }
}
