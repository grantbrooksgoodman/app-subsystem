//
//  BuildInfoOverlayViewObserver.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

final class BuildInfoOverlayViewObserver: Observer {
    // MARK: - Type Aliases

    typealias R = BuildInfoOverlayReducer

    // MARK: - Properties

    let id = UUID()
    let observedValues: [any ObservableProtocol] = [
        Observables.breadcrumbsDidCapture,
        Observables.rootViewTapped,
    ]
    let viewModel: ViewModel<BuildInfoOverlayReducer>

    private var touchTimer: Timer?

    // MARK: - Init

    init(_ viewModel: ViewModel<BuildInfoOverlayReducer>) {
        self.viewModel = viewModel
    }

    // MARK: - Observer Conformance

    func linkObservables() {
        Observers.link(BuildInfoOverlayViewObserver.self, with: observedValues)
    }

    func onChange(of observable: Observable<Any>) {
        Logger.log(
            "\(observable.value is Nil ? "Triggered" : "Observed change of") .\(observable.key.rawValue).",
            domain: .observer,
            sender: self
        )

        switch observable.key {
        case .breadcrumbsDidCapture:
            send(.breadcrumbsDidCapture)

        case .rootViewTapped:
            touchTimer?.invalidate()
            touchTimer = nil

            send(.shouldUseTranslucentAppearanceChanged(true))
            touchTimer = .scheduledTimer(
                timeInterval: 5,
                target: self,
                selector: #selector(touchTimerAction),
                userInfo: nil,
                repeats: true
            )

        default: ()
        }
    }

    func send(_ action: BuildInfoOverlayReducer.Action) {
        Task { @MainActor in
            viewModel.send(action)
        }
    }

    // MARK: - Auxiliary

    @objc
    private func touchTimerAction() {
        guard let touchTimer,
              touchTimer.isValid else {
            touchTimer?.invalidate()
            touchTimer = nil
            return
        }

        send(.shouldUseTranslucentAppearanceChanged(false))
    }
}
