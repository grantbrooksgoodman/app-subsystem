//
//  RootWindowObserver.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

struct RootWindowObserver: Observer {
    // MARK: - Type Aliases

    typealias R = RootWindowReducer

    // MARK: - Properties

    let id = UUID()
    let observedValues: [any ObservableProtocol] = [Observables.isBuildInfoOverlayHidden]
    let viewModel: ViewModel<RootWindowReducer>

    // MARK: - Init

    init(_ viewModel: ViewModel<RootWindowReducer>) {
        self.viewModel = viewModel
    }

    // MARK: - Observer Conformance

    func linkObservables() {
        Observers.link(RootWindowObserver.self, with: observedValues)
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

        default: ()
        }
    }

    func send(_ action: RootWindowReducer.Action) {
        Task { @MainActor in
            viewModel.send(action)
        }
    }
}
