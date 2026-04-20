//
//  BuildInfoOverlayViewObserver.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

final class BuildInfoOverlayViewObserver: Observer, @unchecked Sendable {
    // MARK: - Type Aliases

    typealias R = BuildInfoOverlayReducer

    // MARK: - Properties

    let observedValues: [any ObservableProtocol] = [
        Observables.breadcrumbsDidCapture,
        Observables.rootViewTapped,
    ]

    let viewModel: ViewModel<BuildInfoOverlayReducer>

    private let _touchTimer = LockIsolated<Timer?>(wrappedValue: nil)

    // MARK: - Computed Properties

    private var touchTimer: Timer? {
        get { _touchTimer.wrappedValue }
        set { _touchTimer.wrappedValue = newValue }
    }

    // MARK: - Init

    init(_ viewModel: ViewModel<BuildInfoOverlayReducer>) {
        self.viewModel = viewModel
    }

    // MARK: - Observer Conformance

    func onChange(of observable: Observable<Any>) {
        Logger.log(
            "\(observable.value is Nil ? "Triggered" : "Observed change of") \(observable).",
            domain: .observer,
            sender: self
        )

        switch observable {
        case Observables.breadcrumbsDidCapture:
            send(.breadcrumbsDidCapture)

        case Observables.rootViewTapped:
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

    // MARK: - Auxiliary

    @objc
    private func touchTimerAction() {
        guard let touchTimer,
              touchTimer.isValid else {
            touchTimer?.invalidate()
            return touchTimer = nil
        }

        send(.shouldUseTranslucentAppearanceChanged(false))
    }
}
