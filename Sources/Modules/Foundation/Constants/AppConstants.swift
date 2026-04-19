//
//  AppConstants.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A namespace for app-level constants, organized by value
/// type.
///
/// `AppConstants` provides empty inner enums that your app
/// extends with domain-scoped constant values.
///
/// ```swift
/// extension AppConstants.CGFloats {
///     enum ProfileView {
///         static let avatarSize: CGFloat = 80
///         static let headerHeight: CGFloat = 200
///     }
/// }
/// ```
///
/// Group related values under a nested enum named after the feature
/// or view they belong to. This keeps constants discoverable through
/// autocompletion and prevents naming collisions between unrelated
/// parts of the app.
public enum AppConstants {
    // MARK: - CGFloat

    /// Numeric constants such as sizes, padding, and layout values.
    public enum CGFloats {}

    // MARK: - Color

    /// Color constants such as palette definitions and semantic
    /// color names.
    public enum Colors {}

    // MARK: - String

    /// String constants such as identifiers, keys, and display
    /// text.
    public enum Strings {}
}
