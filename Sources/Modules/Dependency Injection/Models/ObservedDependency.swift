//
//  ObservedDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/// A property wrapper that provides an observable dependency to a SwiftUI
/// view.
///
/// Use `@ObservedDependency` when a view needs to subscribe to published
/// changes from a dependency that conforms to `ObservableObject`:
///
/// ```swift
/// struct SettingsView: View {
///     @ObservedDependency(\.themeService) var themeService: ThemeService
///
///     var body: some View {
///         Text(themeService.currentTheme.name)
///     }
/// }
/// ```
///
/// The wrapper resolves the dependency from ``DependencyValues`` and
/// holds it as an `@ObservedObject`, so the view automatically updates
/// whenever the dependency publishes a change. Access the projected
/// value (`$themeService`) to obtain bindings to the dependency's
/// published properties.
///
/// For non-view code that only needs to read a dependency without
/// observing changes, use ``Dependency`` instead.
///
/// - SeeAlso: ``Dependency``, ``DependencyValues``
@MainActor
@propertyWrapper
public struct ObservedDependency<Value>: DynamicProperty where Value: ObservableObject {
    // MARK: - Properties

    @ObservedObject private var value: Value

    // MARK: - Computed Properties

    /// A binding wrapper for the dependency's published properties.
    public var projectedValue: ObservedObject<Value>.Wrapper { $value }

    /// The resolved dependency instance.
    public var wrappedValue: Value { value }

    // MARK: - Init

    /// Creates an observed dependency accessor for the given key path.
    ///
    /// - Parameter keyPath: A key path to the desired
    ///   `ObservableObject` property on ``DependencyValues``.
    public init(_ keyPath: KeyPath<DependencyValues, Value>) {
        value = DependencyValues.current[keyPath: keyPath]
    }
}
