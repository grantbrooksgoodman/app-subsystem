//
//  ObserverProtocol.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public protocol Observer {
    // MARK: - Associated Types

    associatedtype R: Reducer
    associatedtype V: ViewModel<R>

    // MARK: - Properties

    var id: UUID { get }
    var observedValues: [any ObservableProtocol] { get }
    var viewModel: V { get }

    // MARK: - Methods

    func linkObservables()
    func onChange(of observable: Observable<Any>)
    func send(_ action: R.Action)
}
