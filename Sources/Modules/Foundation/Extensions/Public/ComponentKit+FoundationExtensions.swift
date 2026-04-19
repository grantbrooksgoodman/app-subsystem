//
//  ComponentKit+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/* Proprietary */
import ComponentKit

@MainActor
public extension ComponentKit {
    /// Returns a symbol button tinted with the current theme's `.accent` color.
    func button(
        symbolName: String,
        weight: SwiftUI.Font.Weight? = nil,
        usesIntrinsicSize: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Components.button(
            symbolName: symbolName,
            foregroundColor: .accent,
            weight: weight,
            usesIntrinsicSize: usesIntrinsicSize,
            action: action
        )
    }

    /// Returns a text button tinted with the current theme's `.accent` color.
    func button(
        _ text: String,
        font: ComponentKit.Font = .system,
        isInspectable: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Components.button(
            text,
            font: font,
            foregroundColor: .accent,
            isInspectable: isInspectable,
            action: action
        )
    }

    /// Returns a bordered-prominent capsule button with themed
    /// defaults.
    func capsuleButton(
        _ text: String,
        backgroundColor: Color = .accent,
        font: Font,
        foregroundColor: Color = .background,
        secondaryForegroundColor: Color? = nil,
        usesShadow: Bool = true,
        isInspectable: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Components.button(
            text,
            font: font,
            foregroundColor: foregroundColor,
            secondaryForegroundColor: secondaryForegroundColor,
            isInspectable: isInspectable
        ) {
            action()
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(backgroundColor)
        .if(usesShadow) {
            $0.shadow(
                color: .black.opacity(0.2),
                radius: 10,
                x: 0,
                y: 5
            )
        }
    }

    /// Returns a symbol image tinted with the current theme's `.accent` color.
    func symbol(
        _ systemName: String,
        weight: SwiftUI.Font.Weight? = nil,
        usesIntrinsicSize: Bool = true
    ) -> some View {
        Components.symbol(
            systemName,
            foregroundColor: .accent,
            weight: weight,
            usesIntrinsicSize: usesIntrinsicSize
        )
    }

    /// Returns a text view using the current theme's `.titleText` color.
    func text(
        _ text: String,
        font: ComponentKit.Font = .system,
        isInspectable: Bool = false
    ) -> some View {
        Components.text(
            text,
            font: font,
            foregroundColor: .titleText,
            isInspectable: isInspectable
        )
    }
}
