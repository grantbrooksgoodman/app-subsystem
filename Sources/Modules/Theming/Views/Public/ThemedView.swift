//
//  ThemedView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/// A container view that automatically responds to theme changes.
///
/// Wrap your view's content in a `ThemedView` so that it updates when the
/// active theme changes:
///
/// ```swift
/// var body: some View {
///     ThemedView {
///         Text("Hello")
///             .foregroundStyle(.titleText)
///     }
/// }
/// ```
///
/// By default, themed views update their colors in place without
/// rebuilding the view hierarchy. Set `redrawsOnAppearanceChange` to
/// `true` when the view tree itself depends on theme values resolved at
/// construction time.
///
/// ## Navigation Bar Appearance
///
/// Pass a `navigationBarAppearance` to apply a custom navigation bar
/// style while this view is visible. If
/// `restoresNavigationBarAppearanceOnDisappear` is also `true`, the
/// previous appearance is restored when the view disappears.
public struct ThemedView: View {
    // MARK: - Properties

    private let navigationBarAppearance: NavigationBarAppearance?
    private let redrawsOnAppearanceChange: Bool // swiftlint:disable:next identifier_name
    private let restoresNavigationBarAppearanceOnDisappear: Bool
    private let viewBody: () -> any View

    // MARK: - Init

    /// Creates a themed view with the given options.
    ///
    /// - Parameters:
    ///   - navigationBarAppearance: A custom navigation bar appearance to
    ///     apply while this view is visible. Pass `nil` to leave the
    ///     navigation bar unchanged. Defaults to `nil`.
    ///   - redrawsOnAppearanceChange: A Boolean value that determines
    ///     whether the entire view hierarchy is rebuilt on theme changes.
    ///     Defaults to `false`.
    ///   - restoresNavigationBarAppearanceOnDisappear: A Boolean value
    ///     that determines whether the previous navigation bar appearance
    ///     is restored when this view disappears. Defaults to `false`.
    ///   - body: A closure that returns the themed content.
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

    // MARK: - Init

    init(_ viewModel: ViewModel<ThemedReducer>) {
        _viewModel = .init(
            wrappedValue: viewModel
                .observing(Shared.themedViewAppearanceChanged.events) {
                    _ in .appearanceChanged
                }
        )
    }

    // MARK: - View

    var body: some View {
        viewModel
            .body()
            .eraseToAnyView()
            .id(viewModel.viewID)
            .onFirstAppear {
                viewModel.send(.viewAppeared)
            }
            .onDisappear {
                viewModel.send(.viewDisappeared)
            }
    }
}
