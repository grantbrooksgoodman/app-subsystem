//
//  Toast+Type.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension Toast {
    /// The visual presentation type of a toast.
    ///
    /// A toast can appear as either a full-width ``banner`` or a
    /// compact ``capsule``. Banners offer additional customization
    /// through an appearance edge, a color palette, and a dismiss
    /// button.
    enum ToastType: Equatable, Sendable {
        // MARK: - Cases

        /// A full-width banner that slides in from the specified edge.
        ///
        /// - Parameters:
        ///   - style: The semantic style. The default is ``Style/none``.
        ///   - appearanceEdge: The screen edge the banner appears from.
        ///     The default is ``AppearanceEdge/top``.
        ///   - colorPalette: An optional custom color palette.
        ///   - showsDismissButton: Whether to show a dismiss button.
        ///     Defaults to `true`.
        case banner(
            style: Toast.Style = .none,
            appearanceEdge: Toast.AppearanceEdge = .top,
            colorPalette: Toast.ColorPalette? = nil,
            showsDismissButton: Bool = true
        )

        /// A compact, pill-shaped notification.
        ///
        /// - Parameter style: The semantic style. Defaults to
        ///   ``Style/none``.
        case capsule(style: Toast.Style = .none)

        // MARK: - Properties

        var appearanceEdge: Toast.AppearanceEdge? {
            switch self {
            case let .banner(
                style: _,
                appearanceEdge: appearanceEdge,
                colorPalette: _,
                showsDismissButton: _
            ): appearanceEdge

            default: nil
            }
        }

        var colorPalette: Toast.ColorPalette? {
            switch self {
            case let .banner(
                style: _,
                appearanceEdge: _,
                colorPalette: colorPalette,
                showsDismissButton: _
            ): colorPalette

            default: nil
            }
        }

        var showsDismissButton: Bool? {
            switch self {
            case let .banner(
                style: _,
                appearanceEdge: _,
                colorPalette: _,
                showsDismissButton: showsDismissButton
            ): showsDismissButton

            default: nil
            }
        }

        var style: Toast.Style {
            switch self {
            case let .banner(
                style: style,
                appearanceEdge: _,
                colorPalette: _,
                showsDismissButton: _
            ): style

            case let .capsule(
                style: style
            ): style
            }
        }
    }
}
