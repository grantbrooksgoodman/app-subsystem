//
//  RootOverlayViewObserver.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

struct RootOverlayViewObserver: Observer {
    // MARK: - Type Aliases

    typealias R = RootOverlayReducer

    // MARK: - Properties

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

    func onChange(of observable: Observable<Any>) {
        Logger.log(
            "\(observable.value is Nil ? "Triggered" : "Observed change of") \(observable).",
            domain: .observer,
            sender: self
        )

        switch observable {
        case Observables.isBuildInfoOverlayHidden:
            send(.isBuildInfoOverlayHiddenChanged(
                Observables.isBuildInfoOverlayHidden.value
            ))

        case Observables.rootViewSheet:
            send(.sheetChanged(
                Observables.rootViewSheet.value
            ))

        case Observables.rootViewToast:
            send(.toastChanged(
                Observables.rootViewToast.value
            ))

        case Observables.rootViewToastAction:
            send(.toastActionChanged(
                Observables.rootViewToastAction.value
            ))

        default: ()
        }
    }
}
