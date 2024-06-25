//
//  RootWindow.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

struct RootWindow: View {
    // MARK: - Constants Accessors

    private typealias Floats = FoundationConstants.CGFloats.RootWindow

    // MARK: - Properties

    private let view: any View

    @StateObject private var observer: ViewObserver<RootWindowObserver>
    @StateObject private var viewModel: ViewModel<RootWindowReducer>

    // MARK: - Init

    init(
        _ viewModel: ViewModel<RootWindowReducer>,
        view: any View
    ) {
        _viewModel = .init(wrappedValue: viewModel)
        _observer = .init(wrappedValue: .init(.init(viewModel)))
        self.view = view
    }

    // MARK: - View

    var body: some View {
        ZStack {
            AnyView(view)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    BuildInfoOverlayView(.init(
                        initialState: .init(),
                        reducer: BuildInfoOverlayReducer()
                    ))
                    .frame(maxHeight: Floats.buildInfoOverlayFrameMaxHeight)
                }
            }
            .opacity(viewModel.isBuildInfoOverlayHidden ? 0 : 1)
            .padding(.vertical, 1)
            .ignoresSafeArea()
        }
        .onFirstAppear {
            viewModel.send(.viewAppeared)
        }
    }
}
