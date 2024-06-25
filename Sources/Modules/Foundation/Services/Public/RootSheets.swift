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

    private static var onDismiss: (() -> Void)?

    // MARK: - Present

    public static func present(
        _ sheet: RootSheet,
        onDismiss: (() -> Void)? = nil
    ) {
        Task { @MainActor in
            Observables.rootViewSheet.value = sheet.view
            self.onDismiss = onDismiss
        }
    }

    // MARK: - Dismiss

    public static func dismiss() {
        Task { @MainActor in
            Observables.rootViewSheet.value = nil
            onDismiss?()
            onDismiss = nil
        }
    }
}
