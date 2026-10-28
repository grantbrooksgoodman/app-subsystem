//
//  SquareIconView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/* Proprietary */
import ComponentKit

/// A rounded square icon with a configurable overlay.
///
/// Use `SquareIconView` to display a colored, rounded square
/// containing an image resource, a symbol, or text, as described by
/// its ``Configuration``:
///
/// ```swift
/// SquareIconView(
///     .init(
///         backgroundColor: .blue,
///         overlay: .symbol(name: "gear")
///     )
/// )
/// ```
///
/// To use the icon where a `UIImage` is required – such as a
/// ``ListRowView`` leading image – call ``image(_:)``, which renders
/// the icon once and caches the result per configuration.
///
/// - SeeAlso: ``Configuration``, ``SquareIconImageCache``
public struct SquareIconView: View {
    // MARK: - Constants Accessors

    private typealias Colors = FoundationConstants.Colors.SquareIconView
    private typealias Floats = FoundationConstants.CGFloats.SquareIconView

    // MARK: - Properties

    private let configuration: Configuration

    // MARK: - Init

    /// Creates a square icon with the given configuration.
    ///
    /// - Parameter configuration: The configuration that describes
    ///   the icon.
    public init(_ configuration: Configuration) {
        self.configuration = configuration
    }

    // MARK: - View

    public var body: some View {
        Rectangle()
            .frame(
                width: configuration.size.width,
                height: configuration.size.height
            )
            .foregroundStyle(configuration.backgroundColor)
            .cornerRadius(Floats.cornerRadius)
            .if(configuration.includesShadow) {
                $0.shadow(
                    color: Colors.shadow.opacity(Floats.shadowColorOpacity),
                    radius: Floats.shadowRadius,
                    x: 0,
                    y: Floats.shadowYOffset
                )
            }
            .overlay { overlayView }
    }

    private var overlayView: some View {
        Group {
            switch configuration.overlay {
            case let .resource(
                resource,
                foregroundColor: foregroundColor,
                framePercentOfTotalSize: framePercentOfTotalSize,
                weight: weight
            ):
                Image(resource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .fontWeight(weight)
                    .foregroundStyle(foregroundColor)
                    .frame(
                        width: (
                            configuration.size.width * framePercentOfTotalSize
                        ).rounded(.toNearestOrEven),
                        height: (
                            configuration.size.height * framePercentOfTotalSize
                        ).rounded(.toNearestOrEven)
                    )

            case let .symbol(
                name: name,
                foregroundColor: foregroundColor,
                framePercentOfTotalSize: framePercentOfTotalSize,
                weight: weight
            ):
                Components.symbol(
                    name,
                    foregroundColor: foregroundColor,
                    weight: weight,
                    usesIntrinsicSize: false
                )
                .frame(
                    width: (
                        configuration.size.width * framePercentOfTotalSize
                    ).rounded(.toNearestOrEven),
                    height: (
                        configuration.size.height * framePercentOfTotalSize
                    ).rounded(.toNearestOrEven)
                )

            case let .text(
                string: string,
                font: font,
                foregroundColor: foregroundColor
            ):
                Components.text(
                    string,
                    font: font,
                    foregroundColor: foregroundColor
                )
            }
        }
    }

    // MARK: - UIImage Representation

    /// Returns the icon for the given configuration, rendered as an
    /// image.
    ///
    /// Rendered images are cached in memory per configuration. Call
    /// ``SquareIconImageCache/clearCache()`` to discard them.
    ///
    /// - Parameter configuration: The configuration that describes
    ///   the icon.
    ///
    /// - Returns: The rendered image; otherwise, `nil` if rendering
    ///   fails.
    public static func image(_ configuration: Configuration) -> UIImage? {
        if let cachedImage = SquareIconImageCache.image(forEncodedHash: configuration.encodedHash) {
            return cachedImage
        }

        let image = ImageRenderer(content: SquareIconView(configuration)).uiImage
        SquareIconImageCache.setImage(
            image,
            forEncodedHash: configuration.encodedHash
        )

        return image
    }
}
