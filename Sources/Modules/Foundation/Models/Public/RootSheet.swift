//
//  RootSheet.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/// A type-erased view intended for presentation as a sheet from the
/// app's root view.
///
/// Wrap any SwiftUI view in a `RootSheet` and pass it to
/// ``RootSheets/present(_:onDismiss:)`` to display it as a modal sheet
/// at the root level of the view hierarchy:
///
/// ```swift
/// RootSheets.present(
///     RootSheet(AnyView(SettingsView())),
///     onDismiss: { print("dismissed") }
/// )
/// ```
///
/// Presenting from the root ensures the sheet appears above all other
/// content, regardless of the current navigation depth.
///
/// - SeeAlso: ``RootSheets``
public struct RootSheet: @unchecked Sendable {
    // MARK: - Properties

    let view: AnyView

    // MARK: - Init

    /// Creates a root sheet wrapping the given view.
    ///
    /// - Parameter view: The view to present as a sheet.
    public init(_ view: AnyView) {
        self.view = view
    }
}
