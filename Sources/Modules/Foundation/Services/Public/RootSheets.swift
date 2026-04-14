//
//  RootSheets.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

@MainActor
public enum RootSheets {
    // MARK: - Properties

    private static var onDismiss: (@MainActor () -> Void)?

    // MARK: - Present

    public static func present(
        _ sheet: RootSheet,
        onDismiss: (@MainActor () -> Void)? = nil
    ) {
        Observables.rootViewSheet.value = sheet.view
        self.onDismiss = onDismiss
    }

    // MARK: - Dismiss

    public static func dismiss() {
        Observables.rootViewSheet.value = nil
        onDismiss?()
        onDismiss = nil
    }
}
