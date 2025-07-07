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

public extension ComponentKit {
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

    func button(
        _ text: String,
        font: ComponentKit.Font = .system,
        action: @escaping () -> Void
    ) -> some View {
        Components.button(
            text,
            font: font,
            foregroundColor: .accent,
            action: action
        )
    }

    func capsuleButton(
        _ text: String,
        backgroundColor: Color = .accent,
        font: Font,
        foregroundColor: Color = .background,
        secondaryForegroundColor: Color? = nil,
        usesShadow: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Components.button(
            text,
            font: font,
            foregroundColor: foregroundColor,
            secondaryForegroundColor: secondaryForegroundColor
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

    func text(_ text: String, font: ComponentKit.Font = .system) -> some View {
        Components.text(
            text,
            font: font,
            foregroundColor: .titleText
        )
    }
}
