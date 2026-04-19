//
//  DevModeAction.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A single action that appears in the Developer Mode menu.
///
/// Create a `DevModeAction` to expose a debug or diagnostic operation
/// to developers at runtime. Each action has a title, an optional
/// destructive flag, and a closure that performs the work:
///
/// ```swift
/// let resetOnboarding = DevModeAction(
///     title: "Reset Onboarding",
///     isDestructive: true
/// ) {
///     UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
/// }
/// ```
///
/// Register the action with ``DevModeService`` to make it available in
/// the Developer Mode action sheet:
///
/// ```swift
/// DevModeService.addAction(resetOnboarding)
/// ```
///
/// Two actions are considered equal when their ``title`` and
/// ``isDestructive`` properties match. Adding an action whose metadata
/// matches an existing one replaces the original.
///
/// - SeeAlso: ``DevModeService``
public struct DevModeAction: Sendable {
    // MARK: - Properties

    /// A Boolean value that indicates whether the action is destructive.
    ///
    /// When `true`, the action is presented with a destructive style in
    /// the Developer Mode action sheet.
    public let isDestructive: Bool

    /// The closure to execute when the developer selects this action.
    public let perform: @Sendable () -> Void

    /// The display title shown in the Developer Mode action sheet.
    public let title: String

    // MARK: - Init

    /// Creates a Developer Mode action with the given title and
    /// behavior.
    ///
    /// - Parameters:
    ///   - title: The display title for the action.
    ///   - isDestructive: A Boolean value that indicates whether the
    ///     action should be styled as destructive. The default is
    ///     `false`.
    ///   - perform: The closure to execute when the action is selected.
    public init(
        title: String,
        isDestructive: Bool = false,
        perform: @escaping @Sendable () -> Void
    ) {
        self.title = title
        self.isDestructive = isDestructive
        self.perform = perform
    }

    // MARK: - Equality Comparison

    /// Returns a Boolean value indicating whether this action's
    /// metadata matches the given action's metadata.
    ///
    /// Two actions are considered equal when both their ``title`` and
    /// ``isDestructive`` properties are identical. The ``perform``
    /// closure is not compared.
    ///
    /// - Parameter action: The action to compare against.
    ///
    /// - Returns: `true` if the metadata matches; otherwise, `false`.
    public func metadata(isEqual action: DevModeAction) -> Bool {
        guard title == action.title,
              isDestructive == action.isDestructive else { return false }
        return true
    }

    /// Returns a Boolean value indicating whether this action's
    /// metadata matches the given title and destructive flag.
    ///
    /// - Parameter data: A tuple containing the title and destructive
    ///   flag to compare against.
    ///
    /// - Returns: `true` if the metadata matches; otherwise, `false`.
    public func metadata(isEqual data: (title: String, isDestructive: Bool)) -> Bool {
        guard title == data.title,
              isDestructive == data.isDestructive else { return false }
        return true
    }
}
