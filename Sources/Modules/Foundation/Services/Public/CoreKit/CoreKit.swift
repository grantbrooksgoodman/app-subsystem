//
//  CoreKit.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A collection of core services for dispatch, progress display, UI
/// management, and general utilities.
///
/// `CoreKit` acts as a single entry point for commonly needed
/// subsystem services. Access it through the dependency system:
///
/// ```swift
/// @Dependency(\.coreKit) var core: CoreKit
/// core.hud.showProgress(text: "Loading...")
/// core.ui.present(viewController)
/// ```
///
/// The struct groups four service namespaces:
///
/// - **``GCD``** – Synchronous main-thread dispatch.
/// - **``HUD``** – Progress and status indicator presentation.
/// - **``UI``** – Overlay management, view-controller presentation,
///   and interface-style overrides.
/// - **``Utilities``** – Cache clearing, directory erasure, language
///   configuration, and diagnostics.
///
/// - SeeAlso: ``CoreKitDependency``
public struct CoreKit: Sendable {
    // MARK: - Properties

    /// Grand Central Dispatch helpers.
    public let gcd: GCD

    /// Progress and status indicator management.
    public let hud: HUD

    /// User interface and presentation services.
    public let ui: UI

    /// General-purpose utilities.
    public let utils: Utilities

    // MARK: - Init

    init(
        gcd: GCD,
        hud: HUD,
        ui: UI,
        utils: Utilities
    ) {
        self.gcd = gcd
        self.hud = hud
        self.ui = ui
        self.utils = utils
    }
}
