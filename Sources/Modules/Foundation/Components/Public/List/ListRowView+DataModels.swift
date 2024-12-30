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
    struct Configuration: Equatable {
        // MARK: - Properties

        // String
        public let footerText: String?
        public let headerText: String?
        public let innerText: String

        // Other
        public let cornerRadius: CGFloat
        public let imageView: (() -> (any View))?
        public let interaction: Interaction
        public let isEnabled: Bool

        // MARK: - Init

        public init(
            _ interaction: Interaction,
            headerText: String? = nil,
            innerText: String,
            footerText: String? = nil,
            isEnabled: Bool = true,
            cornerRadius: CGFloat = 10,
            imageView: (() -> any View)? = nil
        ) {
            self.interaction = interaction
            self.headerText = headerText
            self.innerText = innerText
            self.footerText = footerText
            self.isEnabled = isEnabled
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
            let sameInteraction = left.interaction == right.interaction
            let sameIsEnabled = left.isEnabled == right.isEnabled

            guard sameCornerRadius,
                  sameFooterText,
                  sameHeaderText,
                  sameImageViewDebugDescription,
                  sameInnerText,
                  sameInteraction,
                  sameIsEnabled else { return false }

            return true
        }
    }

    enum Interaction: Equatable {
        // MARK: - Cases

        case button(_ id: UUID = UUID(), showsChevron: Bool = false, action: () -> Void)
        case destination(id: UUID = UUID(), _ view: any View)
        case `switch`(_ id: UUID = UUID(), isToggled: Binding<Bool>)

        // MARK: - Properties

        public var buttonAction: (() -> Void)? {
            switch self {
            case let .button(_, showsChevron: _, action: action): return action
            case .destination: return nil
            case .switch: return nil
            }
        }

        public var buttonShowsChevron: Bool? {
            switch self {
            case let .button(_, showsChevron: showsChevron, action: _): return showsChevron
            case .destination: return nil
            case .switch: return nil
            }
        }

        public var destination: (any View)? {
            switch self {
            case .button: return nil
            case let .destination(_, view): return view
            case .switch: return nil
            }
        }

        public var isSwitchToggled: Binding<Bool>? {
            switch self {
            case .button: return nil
            case .destination: return nil
            case let .switch(_, isToggled: isToggled): return isToggled
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
