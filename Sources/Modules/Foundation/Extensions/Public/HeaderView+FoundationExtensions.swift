//
//  HeaderView+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

public extension HeaderView.PeripheralButtonType {
    static func backButton(
        foregroundColor: Color = .accent,
        isEnabled: Bool = true,
        _ action: @escaping () -> Void
    ) -> HeaderView.PeripheralButtonType {
        .image(
            .init(
                image: .init(
                    foregroundColor: foregroundColor,
                    image: .init(systemName: FoundationConstants.Strings.HeaderView.backButtonImageSystemName),
                    size: .init(
                        width: FoundationConstants.CGFloats.HeaderView.backButtonImageSizeWidth,
                        height: FoundationConstants.CGFloats.HeaderView.backButtonImageSizeHeight
                    ),
                    weight: .medium
                ),
                isEnabled: isEnabled
            ) {
                action()
            }
        )
    }

    static func cancelButton(
        font: Font = .system(size: 17),
        foregroundColor: Color = .accent,
        isEnabled: Bool = true,
        _ action: @escaping () -> Void
    ) -> HeaderView.PeripheralButtonType {
        .text(
            .init(
                text: .init(
                    AppSubsystem.delegates.localizedStrings.cancel,
                    font: font,
                    foregroundColor: foregroundColor
                ),
                isEnabled: isEnabled
            ) {
                action()
            }
        )
    }

    static func doneButton(
        font: Font = .system(
            size: 17,
            weight: .semibold
        ),
        foregroundColor: Color = .accent,
        isEnabled: Bool = true,
        _ action: @escaping () -> Void
    ) -> HeaderView.PeripheralButtonType {
        .text(
            .init(
                text: .init(
                    AppSubsystem.delegates.localizedStrings.done,
                    font: font,
                    foregroundColor: foregroundColor
                ),
                isEnabled: isEnabled
            ) {
                action()
            }
        )
    }
}
