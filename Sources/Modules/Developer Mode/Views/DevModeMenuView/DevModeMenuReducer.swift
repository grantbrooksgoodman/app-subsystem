//
//  DevModeMenuReducer.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

struct DevModeMenuReducer: Reducer {
    // MARK: - Constants Accessors

    private typealias Strings = FoundationConstants.Strings.DevModeMenuView

    // MARK: - Dependencies

    @Dependency(\.notificationCenter) private var notificationCenter: NotificationCenter
    @Dependency(\.uiApplication) private var uiApplication: UIApplication

    // MARK: - Actions

    enum Action {
        case viewAppeared
        case viewDisappeared

        case actionRowTapped(DevModeAction)
        case backHeaderItemTapped
        case destinationRowTapped(path: [String])
        case disableDeveloperModeRowTapped
        case doneHeaderItemTapped
        case navigationPathChanged([[String]])
        case refreshActions
        case switchRowToggled(DevModeAction)
    }

    // MARK: - State

    struct State: Equatable {
        /* MARK: Types */

        struct ActionGroup: Equatable {
            let actions: [DevModeAction]
            let headerText: String?
        }

        fileprivate enum TaskID: Hashable {
            case observeAlertControllerDismissals(UUID)
        }

        /* MARK: Properties */

        let id = UUID()

        var navigationPath = [[String]]()
        var pages: [[String]: [ActionGroup]]

        /* MARK: Init */

        @MainActor
        init() {
            pages = [[]: DevModeMenuReducer.groups(for: [])]
        }

        /* MARK: Methods */

        func groups(for path: [String]) -> [ActionGroup] {
            pages[path] ?? []
        }

        func title(for path: [String]) -> String {
            path.last ?? Strings.headerTitleText
        }
    }

    // MARK: - Init

    init() {}

    // MARK: - Reduce

    func reduce(
        into state: inout State,
        action: Action
    ) -> Effect<Action> {
        switch action {
        case .viewAppeared:
            uiApplication.resignFirstResponders()

            let notificationCenter = notificationCenter
            return .run { send in
                for await _ in notificationCenter.notifications(named: .uiAlertControllerDismissed) {
                    await send(.refreshActions)
                }
            }.cancellable(id: State.TaskID.observeAlertControllerDismissals(state.id))

        case .viewDisappeared:
            return .cancel(id: State.TaskID.observeAlertControllerDismissals(state.id))

        case let .actionRowTapped(devModeAction):
            devModeAction.perform()
            return .task { .refreshActions }

        case .backHeaderItemTapped:
            guard !state.navigationPath.isEmpty else { return .none }
            state.navigationPath.removeLast()

        case let .destinationRowTapped(path):
            state.pages[path] = DevModeMenuReducer.groups(for: path)
            state.navigationPath.append(path)

        case .disableDeveloperModeRowTapped:
            RootSheets.dismiss()
            DevModeService.promptToToggle()

        case .doneHeaderItemTapped:
            RootSheets.dismiss()

        case let .navigationPathChanged(navigationPath):
            state.navigationPath = navigationPath

        case .refreshActions:
            for path in [[]] + state.navigationPath {
                state.pages[path] = DevModeMenuReducer.groups(for: path)
            }

        case let .switchRowToggled(devModeAction):
            devModeAction.perform()
            return .task { .refreshActions }
        }

        return .none
    }

    // MARK: - Auxiliary

    /// Resolves the action groups for the page at the given title
    /// path, reading both domains afresh.
    private static func groups(for path: [String]) -> [State.ActionGroup] {
        let appActions = DevModeService.appDomainActions
        let subsystemActions = DevModeService.subsystemDomainActions

        guard !path.isEmpty else {
            var groups = [State.ActionGroup]()
            if !appActions.isEmpty {
                groups.append(.init(
                    actions: appActions,
                    headerText: Strings.appDomainHeaderText
                ))
            }

            groups.append(.init(
                actions: subsystemActions,
                headerText: Strings.subsystemDomainHeaderText
            ))

            return groups
        }

        var actions = appActions + subsystemActions
        for title in path {
            guard let destination = actions.first(where: { $0.title == title }),
                  case let .destination(nestedActions) = destination.interaction else { return [] }
            actions = nestedActions
        }

        return [.init(actions: actions, headerText: nil)]
    }
}
