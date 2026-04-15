//
//  ObserverProtocol.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A type that bridges ``Observable`` value changes to a view's reducer.
///
/// Each observer watches one or more observables and dispatches actions to a
/// ``ViewModel`` when those values change. Conform to `Observer` to define
/// which observables a view cares about and how each change maps to a
/// reducer action.
///
/// ## Implementing an Observer
///
/// 1. Declare a type alias `R` for your view's reducer.
/// 2. List the observables you want to watch in ``observedValues``.
/// 3. Implement ``onChange(of:)`` and use a `switch` statement to identify
///    which observable changed:
///
/// ```swift
/// struct MyObserver: Observer {
///     typealias R = MyReducer
///
///     let observedValues: [any ObservableProtocol] = [Observables.didLogIn]
///     let viewModel: ViewModel<MyReducer>
///
///     init(_ viewModel: ViewModel<MyReducer>) {
///         self.viewModel = viewModel
///     }
///
///     func onChange(of observable: Observable<Any>) {
///         switch observable {
///         case Observables.didLogIn:
///             send(.refreshUI)
///         default: ()
///         }
///     }
/// }
/// ```
///
/// The ``send(_:)`` and ``linkObservables()`` methods have default
/// implementations and do not need to be provided.
///
/// ## Lifecycle Management
///
/// Observers are not used directly. Wrap them in a ``ViewObserver`` to
/// tie their registration to the lifetime of a SwiftUI view:
///
///     @StateObject private var observer = ViewObserver(MyObserver(viewModel))
///
/// - SeeAlso: ``Observable``, ``ViewObserver``
public protocol Observer: Sendable {
    // MARK: - Associated Types

    /// The reducer type associated with this observer's view model.
    associatedtype R: Reducer

    // MARK: - Properties

    /// The observable values this observer is registered to watch.
    var observedValues: [any ObservableProtocol] { get }

    /// The view model that this observer dispatches actions to.
    ///
    /// - Warning: The observer's identity is derived from this view model's
    ///   object identity. Do not register multiple observer types that share
    ///   the same view model instance – the second registration will silently
    ///   be ignored because its identity collides with the first. Each view
    ///   model should have exactly one associated observer.
    var viewModel: ViewModel<R> { get }

    // MARK: - Methods

    /// Called on the main actor when a watched observable's value changes.
    ///
    /// Use a `switch` statement to pattern-match the incoming observable
    /// against the values listed in ``observedValues``:
    ///
    ///     func onChange(of observable: Observable<Any>) {
    ///         switch observable {
    ///         case Observables.isLoggedIn:
    ///             send(.refreshUI)
    ///         default: ()
    ///         }
    ///     }
    ///
    /// - Parameter observable: A type-erased snapshot of the observable that
    ///   changed. Use pattern matching – not identity checks – to determine
    ///   which observable dispatched the notification.
    func onChange(of observable: Observable<Any>)
}
