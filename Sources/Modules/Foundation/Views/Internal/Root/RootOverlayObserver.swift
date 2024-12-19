//
//  RootOverlayObserver.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

struct RootOverlayObserver: Observer {
    // MARK: - Type Aliases

    typealias R = RootOverlayReducer

    // MARK: - Properties

    let id = UUID()
    let observedValues: [any ObservableProtocol] = [
        Observables.isBuildInfoOverlayHidden,
        Observables.rootViewSheet,
        Observables.rootViewToast,
        Observables.rootViewToastAction,
    ]
    let viewModel: ViewModel<RootOverlayReducer>

    // MARK: - Init

    init(_ viewModel: ViewModel<RootOverlayReducer>) {
        self.viewModel = viewModel
    }

    // MARK: - Observer Conformance

    func linkObservables() {
        Observers.link(RootOverlayObserver.self, with: observedValues)
    }

    func onChange(of observable: Observable<Any>) {
        Logger.log(
            "\(observable.value is Nil ? "Triggered" : "Observed change of") .\(observable.key.rawValue).",
            domain: .observer,
            metadata: [self, #file, #function, #line]
        )

        switch observable.key {
        case .isBuildInfoOverlayHidden:
            guard let value = observable.value as? Bool else { return }
            send(.isBuildInfoOverlayHiddenChanged(value))

        case .rootViewSheet:
            send(.sheetChanged(observable.value as? AnyView))

        case .rootViewToast:
            guard let value = observable.value as? Toast else {
                send(.toastChanged(nil))
                return
            }

            send(.toastChanged(value))

        case .rootViewToastAction:
            guard let value = observable.value as? (() -> Void) else {
                send(.toastActionChanged(nil))
                return
            }

            send(.toastActionChanged(value))

        default: ()
        }
    }

    func send(_ action: RootOverlayReducer.Action) {
        Task { @MainActor in
            viewModel.send(action)
        }
    }
}
