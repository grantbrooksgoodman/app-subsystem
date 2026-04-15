//
//  ViewObserver.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A lifecycle wrapper that ties an ``Observer``'s registration to the
/// lifetime of a SwiftUI view.
///
/// `ViewObserver` registers its observer when created and automatically
/// retracts it when deallocated, ensuring that observers are never leaked or
/// left dangling after a view disappears.
///
/// Use `ViewObserver` as a `@StateObject` inside your view:
///
///     struct MyView: View {
///         @StateObject private var observer: ViewObserver<MyObserver>
///
///         init(viewModel: ViewModel<MyReducer>) {
///             _observer = .init(wrappedValue: .init(MyObserver(viewModel)))
///         }
///
///         var body: some View { ... }
///     }
///
/// - SeeAlso: ``Observer``, ``Observable``
public final class ViewObserver<O: Observer>: ObservableObject {
    // MARK: - Properties

    private let observer: O

    // MARK: - Object Lifecycle

    /// Creates a view observer and registers the given observer to begin
    /// receiving notifications.
    ///
    /// - Parameter observer: The observer to register.
    public init(_ observer: O) {
        self.observer = observer
        Observers.register(observer: self.observer)
    }

    deinit {
        Observers.retract(observer: observer)
    }
}
