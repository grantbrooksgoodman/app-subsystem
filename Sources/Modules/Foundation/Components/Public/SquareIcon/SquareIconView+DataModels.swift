//
//  SquareIconView+DataModels.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/* Proprietary */
import ComponentKit

public extension SquareIconView {
    /// The appearance of a square icon.
    ///
    /// A configuration describes the icon's size, background color,
    /// overlay, and shadow:
    ///
    /// ```swift
    /// SquareIconView.Configuration(
    ///     backgroundColor: .purple,
    ///     overlay: .symbol(name: "figure.2"),
    ///     includesShadow: true
    /// )
    /// ```
    ///
    /// Two configurations are considered equal when their
    /// ``EncodedHashable/encodedHash`` values match.
    struct Configuration: EncodedHashable, Hashable, Sendable {
        // MARK: - Types

        /// The content overlaid on a square icon.
        public enum OverlayConfiguration: Sendable {
            /// An image resource, with its foreground color, frame
            /// size relative to the icon, and font weight.
            ///
            /// The foreground color defaults to white and the frame
            /// to two thirds of the icon's size.
            case resource(
                _ resource: ImageResource,
                foregroundColor: Color = .white,
                framePercentOfTotalSize: CGFloat = 2 / 3,
                weight: Font.Weight? = nil
            )

            /// A symbol, with its foreground color, frame size
            /// relative to the icon, and font weight.
            ///
            /// The foreground color defaults to white and the frame
            /// to two thirds of the icon's size.
            case symbol(
                name: String,
                foregroundColor: Color = .white,
                framePercentOfTotalSize: CGFloat = 2 / 3,
                weight: Font.Weight? = nil
            )

            /// A text string, with its font and foreground color.
            ///
            /// The font defaults to a 60-point system font and the
            /// foreground color to white.
            case text(
                string: String,
                font: ComponentKit.Font = .system(scale: .custom(60)),
                foregroundColor: Color = .white
            )
        }

        // MARK: - Properties

        /// The icon's background color.
        public let backgroundColor: Color

        /// A Boolean value that indicates whether the icon casts a
        /// shadow.
        public let includesShadow: Bool

        /// The content overlaid on the icon.
        public let overlay: OverlayConfiguration

        /// The size of the icon.
        public let size: CGSize

        // MARK: - Computed Properties

        /// The strings that collectively define this instance's
        /// identity for hashing purposes, sorted alphabetically.
        public var hashFactors: [String] {
            [
                backgroundColor.description,
                includesShadow.description,
                overlay.foregroundColor.description,
                overlay.rawValue,
                overlay.framePercentOfTotalSize?.description ?? "",
                .init(overlay.weight?.hashValue ?? 0),
                String(overlay.textFont?.scale.points ?? 0),
                String(overlay.textFont?.type),
                String(overlay.textFont?.type.name),
                size.debugDescription,
            ].sorted()
        }

        // MARK: - Init

        /// Creates a square icon configuration.
        ///
        /// - Parameters:
        ///   - size: The size of the icon. The default is 150 by 150
        ///     points.
        ///   - backgroundColor: The icon's background color.
        ///   - overlay: The content overlaid on the icon.
        ///   - includesShadow: A Boolean value that indicates whether
        ///     the icon casts a shadow. The default is `false`.
        public init(
            size: CGSize = .init(
                width: 150,
                height: 150
            ),
            backgroundColor: Color,
            overlay: OverlayConfiguration,
            includesShadow: Bool = false
        ) {
            self.size = size
            self.backgroundColor = backgroundColor
            self.overlay = overlay
            self.includesShadow = includesShadow
        }

        // MARK: - Equatable Conformance

        public static func == (left: Configuration, right: Configuration) -> Bool {
            left.encodedHash == right.encodedHash
        }

        // MARK: - Hashable Conformance

        public func hash(into hasher: inout Hasher) {
            hasher.combine(encodedHash)
        }
    }
}

private extension SquareIconView.Configuration.OverlayConfiguration {
    var foregroundColor: Color {
        switch self {
        case let .resource(_, foregroundColor, _, _): foregroundColor
        case let .symbol(name: _, foregroundColor, _, _): foregroundColor
        case let .text(string: _, _, foregroundColor): foregroundColor
        }
    }

    var framePercentOfTotalSize: CGFloat? {
        switch self {
        case let .resource(_, _, framePercentOfTotalSize, _): framePercentOfTotalSize
        case let .symbol(name: _, _, framePercentOfTotalSize, _): framePercentOfTotalSize
        case .text: nil
        }
    }

    var rawValue: String {
        switch self {
        case let .resource(resource, _, _, _): resource.hashValue.description
        case let .symbol(name: name, _, _, _): name
        case let .text(string: string, _, _): string
        }
    }

    var textFont: ComponentKit.Font? {
        switch self {
        case .resource,
             .symbol: nil
        case let .text(_, font, _): font
        }
    }

    var weight: Font.Weight? {
        switch self {
        case let .resource(_, _, _, weight): weight
        case let .symbol(name: _, _, _, weight): weight
        case .text: nil
        }
    }
}
