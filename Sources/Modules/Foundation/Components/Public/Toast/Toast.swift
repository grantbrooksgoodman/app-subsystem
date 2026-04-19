//
//  Toast.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A lightweight, non-modal notification that appears over the current
/// content.
///
/// Use `Toast` to present brief messages – such as confirmation of an
/// action, a warning, or an error – without interrupting the user's
/// workflow. A toast can appear as a full-width banner or a compact
/// capsule:
///
/// ```swift
/// Toast(.banner(style: .success), message: "Item saved.")
/// Toast(.capsule(style: .error), message: "Upload failed.")
/// ```
///
/// ## Presentation Style
///
/// The ``ToastType`` controls the visual treatment. Banners support an
/// ``AppearanceEdge``, a ``ColorPalette``, and an optional dismiss
/// button. Capsules are a simpler, pill-shaped alternative.
///
/// ## Duration
///
/// By default, a toast is ``PerpetuationStrategy/persistent`` and
/// remains on screen until the user dismisses it. Use
/// ``PerpetuationStrategy/ephemeral(_:)`` to auto-dismiss after a
/// specified duration.
///
/// - SeeAlso: ``ToastType``, ``Style``, ``PerpetuationStrategy``
public struct Toast: Equatable, Sendable {
    // MARK: - Properties

    let message: String
    let perpetuation: PerpetuationStrategy
    let title: String?
    let type: ToastType

    // MARK: - Init

    /// Creates a toast with the given type, title, message, and
    /// perpetuation strategy.
    ///
    /// - Parameters:
    ///   - type: The presentation type. The default is a plain banner.
    ///   - title: An optional headline. Pass `nil` to omit the title.
    ///   - message: The body text to display.
    ///   - perpetuation: The duration strategy. The default is
    ///     ``PerpetuationStrategy/persistent``.
    public init(
        _ type: ToastType = .banner(),
        title: String? = nil,
        message: String,
        perpetuation: PerpetuationStrategy = .persistent
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.perpetuation = perpetuation
    }
}
