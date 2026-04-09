//
//  RootSheets.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public enum RootSheets {
    // MARK: - Properties

    private nonisolated(unsafe) static var onDismiss: (() -> Void)?

    // MARK: - Present

    @MainActor
    public static func present(
        _ sheet: RootSheet,
        onDismiss: (() -> Void)? = nil
    ) {
        Observables.rootViewSheet.value = sheet.view
        self.onDismiss = onDismiss
    }

    // MARK: - Dismiss

    @MainActor
    public static func dismiss() {
        Observables.rootViewSheet.value = nil
        onDismiss?()
        onDismiss = nil
    }
}
