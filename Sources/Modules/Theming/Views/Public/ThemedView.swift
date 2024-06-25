//
//  ThemedView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

public struct ThemedView: View {
    // MARK: - Properties

    // Bool
    private let redrawsOnAppearanceChange: Bool // swiftlint:disable:next identifier_name
    private let restoresNavigationBarAppearanceOnDisappear: Bool

    // Other
    private let navigationBarAppearance: NavigationBarAppearance?
    private let viewBody: () -> any View

    // MARK: - Init

    public init(
        navigationBarAppearance: NavigationBarAppearance? = nil,
        redrawsOnAppearanceChange: Bool = false, // swiftlint:disable:next identifier_name
        restoresNavigationBarAppearanceOnDisappear: Bool = false,
        body: @escaping () -> any View
    ) {
        viewBody = body
        self.navigationBarAppearance = navigationBarAppearance
        self.redrawsOnAppearanceChange = redrawsOnAppearanceChange
        self.restoresNavigationBarAppearanceOnDisappear = restoresNavigationBarAppearanceOnDisappear
    }

    // MARK: - View

    public var body: some View {
        Themed(
            .init(
                initialState: .init(
                    viewBody,
                    navigationBarAppearance: navigationBarAppearance,
                    redrawsOnAppearanceChange: redrawsOnAppearanceChange,
                    restoresNavigationBarAppearanceOnDisappear: restoresNavigationBarAppearanceOnDisappear
                ),
                reducer: ThemedReducer()
            )
        )
    }
}

private struct Themed: View {
    // MARK: - Properties

    @StateObject private var viewModel: ViewModel<ThemedReducer>
    @StateObject private var observer: ViewObserver<ThemedViewObserver>

    // MARK: - Init

    public init(_ viewModel: ViewModel<ThemedReducer>) {
        _viewModel = .init(wrappedValue: viewModel)
        _observer = .init(wrappedValue: .init(.init(viewModel)))
    }

    // MARK: - View

    public var body: some View {
        AnyView(viewModel.body())
            .id(viewModel.viewID)
            .onFirstAppear {
                viewModel.send(.viewAppeared)
            }
            .onDisappear {
                viewModel.send(.viewDisappeared)
            }
    }
}
