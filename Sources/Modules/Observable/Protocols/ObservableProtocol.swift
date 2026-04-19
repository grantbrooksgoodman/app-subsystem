//
//  ObservableProtocol.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A type-erased protocol that all ``Observable`` instances conform to.
///
/// Because `Observable` is generic, an `Observable<Bool>` and an
/// `Observable<String>` are unrelated types. `ObservableProtocol` provides a
/// common supertype so that observers can declare a heterogeneous list of
/// watched values:
///
///     let observedValues: [any ObservableProtocol] = [
///         Observables.isLoggedIn,      // Observable<Bool>
///         Observables.sessionDidExpire, // Observable<Nil>
///     ]
///
/// You do not need to conform to this protocol directly – ``Observable``
/// already conforms.
public protocol ObservableProtocol: Sendable {}

protocol ObserverRegistrable: AnyObject, Sendable {
    /// Removes all registered observers of the given type.
    func clearObservers(ofType type: Any.Type)

    /// Replaces all registered observers of the given type with the provided list.
    /// Observers of other types are unaffected, allowing multiple observer types
    /// to safely share a single observable.
    func setObservers(
        ofType type: Any.Type,
        _ observers: [any Observer]
    )
}
