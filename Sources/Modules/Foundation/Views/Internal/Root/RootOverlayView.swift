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
    // MARK: - Constants Accessors

    private typealias Floats = FoundationConstants.CGFloats.RootOverlayView

    // MARK: - Properties

    @StateObject private var observer: ViewObserver<RootOverlayViewObserver>
    @StateObject private var viewModel: ViewModel<RootOverlayReducer>

    // MARK: - Computed Properties

    static var fallbackFrame: CGRect {
        @Dependency(\.uiApplication.mainWindow) var mainWindow: UIWindow?
        guard let mainWindow else { return .zero }

        let size: CGSize = .init(
            width: Floats.fallbackFrameWidth,
            height: Floats.fallbackFrameHeight
        )

        var xOrigin = mainWindow.bounds.maxX - (size.width - Floats.fallbackFrameOperand)
        var yOrigin = mainWindow.bounds.maxY - (size.height + Floats.fallbackFrameOperand)

        if mainWindow.safeAreaInsets.bottom > 0 {
            xOrigin = mainWindow.bounds.maxX - max(size.width + mainWindow.safeAreaInsets.right, Floats.fallbackFrameWidth)
            yOrigin = mainWindow.bounds.maxY - max(
                size.height + max(mainWindow.safeAreaInsets.bottom, Floats.fallbackFrameYOriginSafeAreaInsetsOperand),
                Floats.fallbackFrameYOriginMaxYOperand
            )
        }

        return .init(
            x: xOrigin,
            y: yOrigin,
            width: size.width,
            height: size.height
        )
    }

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
        contentView
            .sheet(isPresented: sheetBinding) {
                viewModel.sheet
            }
            .toast(toastBinding, onTap: viewModel.toastAction)
            .onShake {
                viewModel.send(.didShakeDevice)
            }
            .onFirstAppear {
                viewModel.send(.viewAppeared)
            }
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isBuildInfoOverlayHidden {
            EmptyView()
        } else {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    BuildInfoOverlayView(.init(
                        initialState: .init(viewModel.buildInfoOverlayYOffset),
                        reducer: BuildInfoOverlayReducer()
                    ))
                    .frame(maxHeight: Floats.buildInfoOverlayFrameMaxHeight)
                }
            }
            .opacity(viewModel.isBuildInfoOverlayHidden ? 0 : 1)
            .padding(.bottom, 1)
            .ignoresSafeArea(.keyboard)
        }
    }
}
