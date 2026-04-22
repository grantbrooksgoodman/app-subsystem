//
//  UIColor+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

@MainActor
extension UIColor: @MainActor EncodedHashable {
    public var hashFactors: [String] {
        [stableID ?? ""]
    }
}

public extension UIColor {
    /// Creates a color object using the specified RGB/hexadecimal code.
    ///
    /// - Parameter rgb: A hexadecimal integer.
    /// - Parameter alpha: The opacity of the color, from 0.0 to 1.0.
    convenience init(
        rgb: Int,
        alpha: CGFloat = 1.0
    ) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF,
            alpha: alpha
        )
    }

    /// Creates a color object using the specified hexadecimal code.
    ///
    /// - Parameter hex: A hexadecimal integer.
    convenience init(hex: Int) {
        self.init(
            red: (hex >> 16) & 0xFF,
            green: (hex >> 8) & 0xFF,
            blue: hex & 0xFF,
            alpha: 1.0
        )
    }

    private convenience init(
        red: Int,
        green: Int,
        blue: Int,
        alpha: CGFloat = 1.0
    ) {
        self.init(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: alpha
        )
    }

    /// Returns a darker variant of the color, adjusted by the given
    /// percentage.
    func darker(by percentage: CGFloat = 30) -> UIColor? {
        adjust(by: -1 * abs(percentage))
    }

    /// Returns a lighter variant of the color, adjusted by the
    /// given percentage.
    func lighter(by percentage: CGFloat = 30) -> UIColor? {
        adjust(by: abs(percentage))
    }

    private func adjust(by percentage: CGFloat) -> UIColor? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return .init(
            red: min(red + percentage / 100, 1),
            green: min(green + percentage / 100, 1),
            blue: min(blue + percentage / 100, 1),
            alpha: alpha
        )
    }
}

public extension UIColor? {
    /// The SwiftUI `Color` representation, or `nil` when the
    /// optional is `nil`.
    var swiftUIColor: Color? {
        guard let self else { return nil }
        return .init(uiColor: self)
    }
}

@MainActor
private extension UIColor {
    var stableID: String? {
        // swiftlint:disable identifier_name
        var _red: CGFloat = 0
        var _green: CGFloat = 0
        var _blue: CGFloat = 0
        var _alpha: CGFloat = 0
        // swiftlint:enable identifier_name

        var populatedColorValues = false
        UITraitCollection.canonicalColorIDTraits.performAsCurrent {
            if getRed(
                &_red,
                green: &_green,
                blue: &_blue,
                alpha: &_alpha
            ) { populatedColorValues = true }
        }

        guard populatedColorValues else { return nil }

        let red = UInt8(clamping: Int(round(_red * 255)))
        let green = UInt8(clamping: Int(round(_green * 255)))
        let blue = UInt8(clamping: Int(round(_blue * 255)))
        let alpha = UInt8(clamping: Int(round(_alpha * 255)))

        return String(
            format: "%02X%02X%02X%02X",
            red,
            green,
            blue,
            alpha
        )
    }
}

@MainActor
private extension UITraitCollection {
    static let canonicalColorIDTraits = UITraitCollection { traits in
        traits.accessibilityContrast = .normal
        traits.displayGamut = .SRGB
        traits.userInterfaceLevel = .base
        traits.userInterfaceStyle = .light
    }
}
