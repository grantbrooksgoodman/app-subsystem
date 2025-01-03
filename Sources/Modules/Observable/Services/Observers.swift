//
//  Observers.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public enum Observers {
    // MARK: - Properties

    private static var instances = [any Observer]()

    // MARK: - Association

    public static func link<O: Observer>(_ observerType: O.Type, with observables: [any ObservableProtocol]) {
        let keys = observables.map(\.key.rawValue)
        guard let observers = instances.filter({ Swift.type(of: $0) == observerType }) as? [O],
              !observers.isEmpty else {
            logClearedObservers(keys)
            observables.forEach { $0.clearObservers() }
            return
        }

        logSetObservers(observers.map { $0.id.uuidString.components[0 ... 3].joined() }, observableKeys: keys)
        observables.forEach { $0.setObservers(observers) }
    }

    // MARK: - Registration

    public static func register(observer: any Observer) {
        guard !instances.contains(where: { $0.id == observer.id }) else { return }
        instances.append(observer)
        log("Registered", id: observer.id.uuidString.components[0 ... 3].joined())
        observer.linkObservables()
    }

    // MARK: - Retraction

    public static func retract(observer: any Observer) {
        guard let observer = instances.first(where: { $0.id == observer.id }) else { return }
        instances.removeAll(where: { $0.id == observer.id })
        log("Retracted", id: observer.id.uuidString.components[0 ... 3].joined())
        observer.linkObservables()
    }

    // MARK: - Logging

    private static func log(_ action: String, id: String) {
        Logger.log(
            "\(action) observer with ID: \(id).",
            domain: .observer,
            metadata: [self, #file, #function, #line]
        )
    }

    private static func logClearedObservers(_ keys: [String]) {
        Logger.log(
            "Cleared all observers on \(keys).",
            domain: .observer,
            metadata: [self, #file, #function, #line]
        )
    }

    private static func logSetObservers(
        _ observerIDs: [String],
        observableKeys: [String]
    ) {
        Logger.log(
            "Linking \(observerIDs) to \(observableKeys).",
            domain: .observer,
            metadata: [self, #file, #function, #line]
        )
    }
}
