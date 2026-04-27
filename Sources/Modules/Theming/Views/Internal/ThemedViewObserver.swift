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

    let observedValues: [any ObservableProtocol] = [Observables.themedViewAppearanceChanged]
    let viewModel: ViewModel<ThemedReducer>

    // MARK: - Init

    init(_ viewModel: ViewModel<ThemedReducer>) {
        self.viewModel = viewModel
    }

    // MARK: - Observer Conformance

    func onChange(of observable: Observable<Any>) {
        switch observable {
        case Observables.themedViewAppearanceChanged:
            send(.appearanceChanged)

        default: ()
        }
    }
}
