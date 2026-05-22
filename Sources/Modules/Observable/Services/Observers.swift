//
//  Observers.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

enum Observers {
    // MARK: - Properties

    private static let instances = LockIsolated([any Observer]())

    // MARK: - Association

    fileprivate static func link<O: Observer>(
        _ observerType: O.Type,
        with observables: [any ObservableProtocol]
    ) {
        instances.projectedValue.withValue { instances in
            let registrables = observables.compactMap { $0 as? ObserverRegistrable }

            guard let observers = instances.filter({
                Swift.type(of: $0) == observerType
            }) as? [O],
                !observers.isEmpty else {
                return registrables.forEach { $0.clearObservers(ofType: observerType) }
            }

            let anyObservers = observers.map { $0 as any Observer }
            registrables.forEach { $0.setObservers(ofType: observerType, anyObservers) }
        }
    }

    // MARK: - Registration

    static func register(observer: any Observer) {
        var existingType: Any.Type?

        let didAppend = instances.projectedValue.withValue { instances -> Bool in
            if let existingInstance = instances.first(where: { $0.id == observer.id }) {
                existingType = Swift.type(of: existingInstance)
                return false
            }

            instances.append(observer)
            return true
        }

        guard didAppend else {
            Logger.log(
                .init( // swiftlint:disable line_length
                    "OBSERVER REGISTRATION MISUSE:\n[\(Swift.type(of: observer))] shares a view model instance with already-registered [\(existingType.map(String.init(describing:)) ?? "<unknown>")].\nEach view model must have exactly one associated observer.", // swiftlint:enable line_length
                    userInfo: [Exception.UserInfo.staticErrorCode.rawValue: "983A"],
                    metadata: .init(sender: self)
                ),
                showRuntimeWarning: true
            )
            return
        }

        log(
            "Registered",
            id: observer.id
        )

        observer.linkObservables()
    }

    // MARK: - Retraction

    static func retract(observer: any Observer) {
        let retractedObserver: (any Observer)? = instances.projectedValue.withValue { instances in
            guard let instance = instances.first(where: { $0.id == observer.id }) else { return nil }
            instances.removeAll(where: { $0.id == instance.id })
            return instance
        }

        guard let retractedObserver else { return }

        log(
            "Retracted",
            id: retractedObserver.id
        )

        retractedObserver.linkObservables()
    }

    // MARK: - Logging

    private static func log(
        _ action: String,
        id: ObjectIdentifier
    ) {
        Logger.log(
            "\(action) observer with ID: \(id).",
            domain: .observer,
            sender: self
        )
    }
}

public extension Observer {
    // MARK: - Properties

    /// A stable identifier derived from the observer's ``viewModel`` instance.
    var id: ObjectIdentifier {
        .init(viewModel)
    }

    // MARK: - Methods

    /// Re-links this observer type with its declared ``observedValues``.
    ///
    /// This method is called automatically when the observer is registered
    /// or removed.
    ///
    /// - Important: Do not provide your own implementation of this method.
    ///   The default implementation coordinates with the internal observer
    ///   registry; overriding it will silently break observer registration.
    func linkObservables() {
        Observers.link(
            Self.self,
            with: observedValues
        )
    }

    /// Dispatches an action to this observer's view model on the main actor.
    ///
    /// Use this inside ``onChange(of:)`` to forward an observable change to
    /// your view's reducer:
    ///
    ///     case Observables.isLoggedIn:
    ///         send(.refreshUI)
    ///
    /// - Parameter action: The reducer action to dispatch.
    func send(_ action: R.Action) {
        Task { @MainActor in
            viewModel.send(action)
        }
    }
}
