//
//  RootSheets.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// The interface for presenting and dismissing a sheet from the
/// app's root view.
///
/// Use `RootSheets` when you need to present a modal sheet that
/// appears above all other content, regardless of the current
/// navigation depth:
///
/// ```swift
/// RootSheets.present(
///     RootSheet(AnyView(FeedbackView()))
/// )
/// ```
///
/// Call ``dismiss()`` to remove the sheet programmatically. An
/// optional `onDismiss` closure can be provided at presentation time
/// to perform cleanup when the sheet is dismissed.
///
/// - SeeAlso: ``RootSheet``
@MainActor
public enum RootSheets {
    // MARK: - Properties

    private static var onDismiss: (@MainActor () -> Void)?

    // MARK: - Present

    /// Presents the given sheet from the root view.
    ///
    /// - Parameters:
    ///   - sheet: The ``RootSheet`` to present.
    ///   - onDismiss: An optional closure executed when the sheet is
    ///     dismissed.
    public static func present(
        _ sheet: RootSheet,
        onDismiss: (@MainActor () -> Void)? = nil
    ) {
        Shared.rootViewSheet.value = sheet
        self.onDismiss = onDismiss
    }

    // MARK: - Dismiss

    /// Dismisses the currently presented root sheet.
    ///
    /// If an `onDismiss` closure was provided at presentation time,
    /// it is executed and then cleared.
    public static func dismiss() {
        Shared.rootViewSheet.value = nil
        onDismiss?()
        onDismiss = nil
    }
}
