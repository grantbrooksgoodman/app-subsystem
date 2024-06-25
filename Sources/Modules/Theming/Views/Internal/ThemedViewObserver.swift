//
//  ThemedViewObserver.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

struct ThemedViewObserver: Observer {
    // MARK: - Type Aliases

    typealias R = ThemedReducer

    // MARK: - Properties

    let id = UUID()
    let observedValues: [any ObservableProtocol] = [Observables.themedViewAppearanceChanged]
    let viewModel: ViewModel<ThemedReducer>

    // MARK: - Init

    init(_ viewModel: ViewModel<ThemedReducer>) {
        self.viewModel = viewModel
    }

    // MARK: - Observer Conformance

    func linkObservables() {
        Observers.link(ThemedViewObserver.self, with: observedValues)
    }

    func onChange(of observable: Observable<Any>) {
        Logger.log(
            "\(observable.value is Nil ? "Triggered" : "Observed change of") .\(observable.key.rawValue).",
            domain: .observer,
            metadata: [self, #file, #function, #line]
        )

        switch observable.key {
        case .themedViewAppearanceChanged:
            send(.appearanceChanged)
        default: ()
        }
    }

    func send(_ action: ThemedReducer.Action) {
        Task { @MainActor in
            viewModel.send(action)
        }
    }
}
