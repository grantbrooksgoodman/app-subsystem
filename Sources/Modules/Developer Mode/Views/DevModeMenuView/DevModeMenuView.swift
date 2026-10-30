//
//  DevModeMenuView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/* Proprietary */
import ComponentKit

struct DevModeMenuView: View {
    // MARK: - Constants Accessors

    private typealias Colors = FoundationConstants.Colors.DevModeMenuView
    private typealias Floats = FoundationConstants.CGFloats.DevModeMenuView
    private typealias Strings = FoundationConstants.Strings.DevModeMenuView

    // MARK: - Properties

    @StateObject private var viewModel: ViewModel<DevModeMenuReducer>

    // MARK: - Bindings

    private var navigationPathBinding: Binding<[[String]]> {
        viewModel.binding(
            for: \.navigationPath,
            sendAction: { .navigationPathChanged($0) }
        )
    }

    // MARK: - Init

    init(_ viewModel: ViewModel<DevModeMenuReducer>) {
        _viewModel = .init(
            wrappedValue: viewModel
                .observing(
                    SharedEvent(\.devModeMenuRefreshRequested)
                        .wrappedValue
                        .events
                ) { _ in .refreshActions }
        )
    }

    // MARK: - View

    var body: some View {
        NavigationStack(path: navigationPathBinding) {
            page(for: [])
                .navigationDestination(for: [String].self) { path in
                    page(for: path)
                }
        }
        .accentColor(Color.accent)
        .if(!UIApplication.isFullyV26Compatible) { $0.ignoresSafeArea() }
        .onFirstAppear {
            viewModel.send(.viewAppeared)
        }
        .onDisappear {
            viewModel.send(.viewDisappeared)
        }
    }

    private var disableDeveloperModeRow: ListRowView.Configuration {
        .init(
            .button { viewModel.send(.disableDeveloperModeRowTapped) },
            innerText: Strings.disableDeveloperModeRowText,
            innerTextColor: Colors.destructiveRowForeground
        )
    }

    private var doneToolbarButton: some View {
        Components.button(
            Localized(SubsystemStringKey.done).wrappedValue,
            font: .systemSemibold
        ) {
            viewModel.send(.doneHeaderItemTapped)
        }
    }

    // MARK: - Auxiliary

    private func contentView(for path: [String]) -> some View {
        let groups = viewModel.state.groups(for: path)
        return ScrollView {
            VStack(spacing: Floats.groupedListViewSpacing) {
                ForEach(0 ..< groups.count, id: \.self) { index in
                    ThemedView(redrawsOnAppearanceChange: true) {
                        GroupedListView(
                            rows(for: groups[index].actions, at: path),
                            headerText: groups[index].headerText
                        )
                    }
                }

                if path.isEmpty {
                    ThemedView(redrawsOnAppearanceChange: true) {
                        GroupedListView([disableDeveloperModeRow])
                    }
                }
            }
            .padding(.horizontal, Floats.groupedListViewHorizontalPadding)
            .padding(.vertical, Floats.groupedListViewVerticalPadding)
        }
        .scrollBounceBehavior(.basedOnSize, axes: [.vertical])
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.groupedContentBackground)
    }

    private func interaction(
        for action: DevModeAction,
        at path: [String]
    ) -> ListRowView.Interaction {
        switch action.interaction {
        case .button:
            .button { viewModel.send(.actionRowTapped(action)) }

        case .destination:
            .button(showsChevron: true) {
                viewModel.send(.destinationRowTapped(path: path + [action.title]))
            }

        case let .switch(isOn):
            .switch(isToggled: .init(
                get: { isOn },
                set: { _ in viewModel.send(.switchRowToggled(action)) }
            ))
        }
    }

    @ViewBuilder
    private func page(for path: [String]) -> some View {
        let title = viewModel.state.title(for: path)
        let isRoot = path.isEmpty

        ThemedView(
            redrawsOnAppearanceChange: !isRoot
        ) {
            if UIApplication.isFullyV26Compatible {
                contentView(for: path)
                    .header(
                        .text(.init(title)),
                        rightItem: isRoot ? .doneButton(
                            foregroundColor: .titleText
                        ) { viewModel.send(.doneHeaderItemTapped) } : nil,
                        attributes: .init(sizeClass: .sheet),
                        embedsInNavigationWindow: false
                    )
            } else {
                contentView(for: path)
                    .header(
                        leftItem: isRoot ? nil : .backButton { viewModel.send(.backHeaderItemTapped) },
                        .text(.init(
                            title,
                            foregroundColor: .navigationBarTitle
                        )),
                        rightItem: isRoot ? .doneButton { viewModel.send(.doneHeaderItemTapped) } : nil,
                        attributes: .init(sizeClass: .sheet),
                        popGestureAction: isRoot ? nil : { viewModel.send(.backHeaderItemTapped) }
                    )
            }
        }
    }

    private func rows(
        for actions: [DevModeAction],
        at path: [String]
    ) -> [ListRowView.Configuration] {
        actions.map { action in
            .init(
                interaction(for: action, at: path),
                innerText: action.title,
                innerTextColor: action.isDestructive ? Colors.destructiveRowForeground : .titleText,
                imageView: action.iconConfiguration.map { configuration in
                    { SquareIconView.image(configuration).swiftUIImage }
                }
            )
        }
    }
}
