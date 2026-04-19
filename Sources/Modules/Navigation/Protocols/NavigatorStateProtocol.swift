//
//  NavigatorStateProtocol.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// The shape of an app's navigation state.
///
/// Conform to `NavigatorState` to declare the three presentation channels
/// available in your app: a navigation stack, a sheet, and a
/// full-screen modal. Each channel uses a ``Paths``-conforming type to
/// enumerate its possible destinations:
///
/// ```swift
/// struct AppNavigationState: NavigatorState {
///    var modal: ModalPath? = nil
///    var sheet: SheetPath? = nil
///    var stack: [SeguePath] = []
/// }
/// ```
///
/// The ``NavigationCoordinator`` publishes changes to these properties so
/// that SwiftUI presentation modifiers – such as `NavigationStack`,
/// `.sheet`, and `.fullScreenCover` – can react automatically.
///
/// - SeeAlso: ``Paths``, ``Navigating``
public protocol NavigatorState {
    // MARK: - Associated Types

    /// The paths available for full-screen modal presentation.
    associatedtype ModalPaths: Paths

    /// The paths available for push navigation on the stack.
    associatedtype SeguePaths: Paths

    /// The paths available for sheet presentation.
    associatedtype SheetPaths: Paths

    // MARK: - Properties

    /// The currently presented full-screen modal, or `nil` if none is
    /// presented.
    var modal: ModalPaths? { get set }

    /// The currently presented sheet, or `nil` if none is presented.
    var sheet: SheetPaths? { get set }

    /// The ordered list of views in the navigation stack.
    var stack: [SeguePaths] { get set }
}

/// A type that represents a navigable destination.
///
/// Conform to `Paths` when defining the destinations for a navigation
/// channel. The ``Hashable`` and ``Identifiable`` requirements allow
/// SwiftUI to track and differentiate each destination in the navigation
/// state.
public protocol Paths: Hashable, Identifiable {}

public extension Paths {
    var id: String { .init() }
}
