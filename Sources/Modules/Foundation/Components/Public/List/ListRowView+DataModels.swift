//
//  ListRowView+DataModels.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

public extension ListRowView {
    /// The complete set of properties that define a list row's content,
    /// appearance, and behavior.
    ///
    /// A `Configuration` pairs an ``Interaction`` with display
    /// properties such as title text, optional header and footer
    /// strings, and a leading image:
    ///
    /// ```swift
    /// ListRowView.Configuration(
    ///     .button { print("tapped") },
    ///     innerText: "Tap Me",
    ///     imageView: { Image(systemName: "star") }
    /// )
    /// ```
    struct Configuration: Equatable {
        // MARK: - Properties

        let cornerRadius: CGFloat
        let footerText: String?
        let headerText: String?
        let imageView: (() -> (any View))?
        let innerText: String
        let innerTextColor: Color
        let interaction: Interaction
        let isEnabled: Bool
        let isInspectable: Bool

        // MARK: - Init

        /// Creates a list row configuration.
        ///
        /// - Parameters:
        ///   - interaction: The row's interaction behavior.
        ///   - headerText: Optional text displayed above the row.
        ///   - innerText: The primary label text.
        ///   - footerText: Optional text displayed below the row.
        ///   - innerTextColor: The label text color. The default is
        ///     the theme's title text color.
        ///   - isEnabled: Whether the row is interactive. The default
        ///     is `true`.
        ///   - isInspectable: Whether the text supports inspection.
        ///     The default is `false`.
        ///   - cornerRadius: The corner radius for standalone rows.
        ///   - imageView: An optional closure returning a leading
        ///     image.
        @MainActor
        public init(
            _ interaction: Interaction,
            headerText: String? = nil,
            innerText: String,
            footerText: String? = nil,
            innerTextColor: Color = .titleText,
            isEnabled: Bool = true,
            isInspectable: Bool = false,
            cornerRadius: CGFloat = UIApplication.isFullyV26Compatible ? 20 : 10,
            imageView: (() -> any View)? = nil
        ) {
            self.interaction = interaction
            self.headerText = headerText
            self.innerText = innerText
            self.footerText = footerText
            self.innerTextColor = innerTextColor
            self.isEnabled = isEnabled
            self.isInspectable = isInspectable
            self.cornerRadius = cornerRadius
            self.imageView = imageView
        }

        // MARK: - Equatable Conformance

        public static func == (left: Configuration, right: Configuration) -> Bool {
            let sameCornerRadius = left.cornerRadius == right.cornerRadius
            let sameFooterText = left.footerText == right.footerText
            let sameHeaderText = left.headerText == right.headerText
            let sameImageViewDebugDescription = left.imageView.debugDescription == right.imageView.debugDescription
            let sameInnerText = left.innerText == right.innerText
            let sameInnerTextColor = left.innerTextColor == right.innerTextColor
            let sameInteraction = left.interaction == right.interaction
            let sameIsEnabled = left.isEnabled == right.isEnabled
            let sameIsInspectable = left.isInspectable == right.isInspectable

            guard sameCornerRadius,
                  sameFooterText,
                  sameHeaderText,
                  sameImageViewDebugDescription,
                  sameInnerText,
                  sameInnerTextColor,
                  sameInteraction,
                  sameIsEnabled,
                  sameIsInspectable else { return false }

            return true
        }
    }

    /// The interaction behavior of a ``ListRowView``.
    ///
    /// Each case determines how the row responds to user input and
    /// what trailing accessory it displays:
    ///
    /// - ``button(_:showsChevron:action:)`` executes a closure on tap.
    /// - ``destination(id:_:)`` pushes a view via `NavigationLink`.
    /// - ``switch(_:isToggled:)`` displays an inline toggle bound to
    ///   a `Binding<Bool>`.
    enum Interaction: Equatable {
        // MARK: - Cases

        /// A tappable row that executes a closure.
        case button(
            _ id: UUID = UUID(),
            showsChevron: Bool = false,
            action: () -> Void
        )

        /// A navigation link that pushes the given view.
        case destination(
            id: UUID = UUID(),
            _ view: any View
        )

        /// A row with an inline toggle.
        case `switch`(
            _ id: UUID = UUID(),
            isToggled: Binding<Bool>
        )

        // MARK: - Properties

        var buttonAction: (() -> Void)? {
            switch self {
            case let .button(_, showsChevron: _, action: action): action
            case .destination: nil
            case .switch: nil
            }
        }

        var buttonShowsChevron: Bool? {
            switch self {
            case let .button(_, showsChevron: showsChevron, action: _): showsChevron
            case .destination: nil
            case .switch: nil
            }
        }

        var destination: (any View)? {
            switch self {
            case .button: nil
            case let .destination(_, view): view
            case .switch: nil
            }
        }

        var isSwitchToggled: Binding<Bool>? {
            switch self {
            case .button: nil
            case .destination: nil
            case let .switch(_, isToggled: isToggled): isToggled
            }
        }

        // MARK: - Equatable Conformance

        public static func == (left: Interaction, right: Interaction) -> Bool {
            switch (left, right) {
            case let (.button(leftID, leftShowsChevron, _), .button(rightID, rightShowsChevron, _)):
                guard leftID == rightID,
                      leftShowsChevron == rightShowsChevron else { return false }
                return true

            case let (.switch(leftID, leftIsToggled), .switch(rightID, rightIsToggled)):
                guard leftID == rightID,
                      leftIsToggled.wrappedValue == rightIsToggled.wrappedValue else { return false }
                return true

            case let (.destination(leftID, _), .destination(rightID, _)):
                return leftID == rightID

            default: return false
            }
        }
    }
}
