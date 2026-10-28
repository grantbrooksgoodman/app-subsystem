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
/// icon, an interaction style, an optional destructive flag, and a
/// closure that performs the work:
///
/// ```swift
/// let resetOnboarding = DevModeAction(
///     title: "Reset Onboarding",
///     iconConfiguration: .init(
///         backgroundColor: .orange,
///         overlay: .symbol(name: "arrow.counterclockwise")
///     ),
///     isDestructive: true
/// ) {
///     UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
/// }
/// ```
///
/// Register the action with ``DevModeService`` to make it available in
/// the Developer Mode menu:
///
/// ```swift
/// DevModeService.addAction(resetOnboarding)
/// ```
///
/// An action that toggles a setting can present as an inline switch
/// instead of a button. Supply the setting's current state through
/// ``Interaction/switch(isOn:)`` and toggle the setting in
/// ``perform``:
///
/// ```swift
/// let verboseLogging = DevModeAction(
///     title: "Verbose Logging",
///     interaction: .switch(isOn: Logger.isVerbose)
/// ) {
///     Logger.isVerbose.toggle()
/// }
/// ```
///
/// To group related actions under their own page, create a
/// destination action. Selecting it pushes a page listing the nested
/// actions, which can themselves include further destinations:
///
/// ```swift
/// let databaseOptions = DevModeAction(
///     title: "Database Options",
///     iconConfiguration: .init(
///         backgroundColor: .blue,
///         overlay: .symbol(name: "cylinder.fill")
///     ),
///     destination: [migrateDatabase, validateIntegrity]
/// )
/// ```
///
/// An action's metadata – its ``title`` and ``isDestructive``
/// properties – identifies it in the menu. Adding an action whose
/// metadata matches an existing one replaces the original.
///
/// - SeeAlso: ``DevModeService``
public struct DevModeAction: Equatable, Sendable {
    // MARK: - Types

    /// The way an action is presented and triggered in the
    /// Developer Mode menu.
    public enum Interaction: Equatable, Sendable {
        /// A tappable row that performs the action when selected.
        case button

        /// A row that pushes a page listing the given actions when
        /// selected.
        ///
        /// The menu resolves the nested actions by title path each
        /// time it refreshes, so the pushed page reflects the latest
        /// values. The action's ``DevModeAction/perform`` closure is
        /// not executed.
        case destination(_ actions: [DevModeAction])

        /// A row with an inline switch that performs the action when
        /// toggled.
        ///
        /// The associated value reflects the current state of the
        /// setting the action toggles. The menu re-reads its actions
        /// after each one performs and whenever it refreshes, so
        /// supply the current state each time the action is created.
        case `switch`(isOn: Bool)
    }

    // MARK: - Properties

    /// The configuration of the icon shown beside the action in the
    /// Developer Mode menu, or `nil` to show no icon.
    public let iconConfiguration: SquareIconView.Configuration?

    /// The way the action is presented and triggered in the Developer
    /// Mode menu.
    public let interaction: Interaction

    /// A Boolean value that indicates whether the action is destructive.
    ///
    /// When `true`, the action is presented with a destructive style in
    /// the Developer Mode menu.
    public let isDestructive: Bool

    /// The closure to execute when the developer selects this action.
    ///
    /// A destination action never executes this closure.
    public let perform: @Sendable () -> Void

    /// The display title shown in the Developer Mode menu.
    public let title: String

    // MARK: - Init

    /// Creates a Developer Mode action with the given title and
    /// behavior.
    ///
    /// - Parameters:
    ///   - title: The display title for the action.
    ///   - iconConfiguration: The configuration of the icon shown
    ///     beside the action, or `nil` to show no icon. The default
    ///     is `nil`.
    ///   - interaction: The way the action is presented and
    ///     triggered. The default is ``Interaction/button``.
    ///   - isDestructive: A Boolean value that indicates whether the
    ///     action should be styled as destructive. The default is
    ///     `false`.
    ///   - perform: The closure to execute when the action is selected.
    public init(
        title: String,
        iconConfiguration: SquareIconView.Configuration? = nil,
        interaction: Interaction = .button,
        isDestructive: Bool = false,
        perform: @escaping @Sendable () -> Void
    ) {
        self.title = title
        self.iconConfiguration = iconConfiguration
        self.interaction = interaction
        self.isDestructive = isDestructive
        self.perform = perform
    }

    /// Creates a Developer Mode action that pushes a page listing the
    /// given actions.
    ///
    /// - Parameters:
    ///   - title: The display title for the action, also used as the
    ///     pushed page's title.
    ///   - iconConfiguration: The configuration of the icon shown
    ///     beside the action, or `nil` to show no icon. The default
    ///     is `nil`.
    ///   - isDestructive: A Boolean value that indicates whether the
    ///     action should be styled as destructive. The default is
    ///     `false`.
    ///   - actions: The actions listed on the pushed page.
    public init(
        title: String,
        iconConfiguration: SquareIconView.Configuration? = nil,
        isDestructive: Bool = false,
        destination actions: [DevModeAction]
    ) {
        self.title = title
        self.iconConfiguration = iconConfiguration
        interaction = .destination(actions)
        self.isDestructive = isDestructive
        perform = {}
    }

    // MARK: - Equatable Conformance

    /// Returns a Boolean value indicating whether two actions are
    /// presented identically.
    ///
    /// Two actions are considered equal when their ``title``,
    /// ``isDestructive``, ``interaction``, and ``iconConfiguration``
    /// properties are identical. The ``perform`` closure is not
    /// compared. To compare identifying metadata alone, use
    /// `metadata(isEqual:)`.
    ///
    /// - Parameters:
    ///   - left: An action to compare.
    ///   - right: Another action to compare.
    ///
    /// - Returns: `true` if the actions are presented identically;
    ///   otherwise, `false`.
    public static func == (left: DevModeAction, right: DevModeAction) -> Bool {
        guard left.metadata(isEqual: right),
              left.interaction == right.interaction,
              left.iconConfiguration == right.iconConfiguration else { return false }
        return true
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
