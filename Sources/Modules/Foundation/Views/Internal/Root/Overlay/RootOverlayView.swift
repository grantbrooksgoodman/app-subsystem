//
//  RootOverlayView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/// Added as a subview to the root window and is perpetually frontmost.
struct RootOverlayView: View {
    // MARK: - Properties

    @StateObject private var observer: ViewObserver<RootOverlayObserver>
    @StateObject private var viewModel: ViewModel<RootOverlayReducer>

    // MARK: - Bindings

    private var sheetBinding: Binding<Bool> {
        viewModel.binding(
            for: \.isPresentingSheet,
            sendAction: { .isPresentingSheetChanged($0) }
        )
    }

    private var toastBinding: Binding<Toast?> {
        viewModel.binding(
            for: \.toast,
            sendAction: { .toastChanged($0) }
        )
    }

    // MARK: - Init

    init(_ viewModel: ViewModel<RootOverlayReducer>) {
        _viewModel = .init(wrappedValue: viewModel)
        _observer = .init(wrappedValue: .init(.init(viewModel)))
    }

    // MARK: - View

    var body: some View {
        EmptyView()
            .sheet(isPresented: sheetBinding) {
                viewModel.sheet
            }
            .toast(toastBinding, onTap: viewModel.toastAction)
            .onFirstAppear {
                viewModel.send(.viewAppeared)
            }
    }
}
