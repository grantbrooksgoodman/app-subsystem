//
//  Toast+ColorPalette.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

public extension Toast {
    /// A set of colors that override the default appearance of a banner-style
    /// toast.
    ///
    /// Supply a `ColorPalette` when you need a toast whose colors
    /// differ from the defaults provided by the toast's ``Style``.
    /// Each property is optional; when `nil`, the corresponding default
    /// color is used.
    struct ColorPalette: Equatable, Sendable {
        // MARK: - Properties

        let accent: Color?
        let background: Color?
        let dismissButton: Color?
        let text: Color?

        // MARK: - Init

        /// Creates a color palette with the given overrides.
        ///
        /// Pass `nil` for any color to fall back to the toast style's
        /// default.
        ///
        /// - Parameters:
        ///   - accent: The icon accent color.
        ///   - background: The banner background color.
        ///   - dismissButton: The dismiss button color.
        ///   - text: The text color.
        public init(
            accent: Color? = nil,
            background: Color? = nil,
            dismissButton: Color? = nil,
            text: Color? = nil
        ) {
            self.accent = accent
            self.background = background
            self.dismissButton = dismissButton
            self.text = text
        }
    }
}
