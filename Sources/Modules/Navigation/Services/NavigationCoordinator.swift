//
//  NavigationCoordinator.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

public final class NavigationCoordinator<N: Navigating>: ObservableObject {
    // MARK: - Properties

    @Published public private(set) var state: N.State
    private let navigating: N

    // MARK: - Init

    public init(_ state: N.State, navigating: N) {
        self.state = state
        self.navigating = navigating
    }

    // MARK: - Navigable

    public func navigable<Value>(
        _ keyPath: KeyPath<N.State, Value>,
        route transform: @escaping (Value) -> N.Route
    ) -> Binding<Value> {
        Binding<Value>(
            get: { self.state[keyPath: keyPath] },
            set: { self.navigate(to: transform($0)) }
        )
    }

    // MARK: - Navigate To

    public func navigate(to route: N.Route) {
        DispatchQueue.main.async {
            self.navigating.navigate(to: route, on: &self.state)
        }
    }
}
