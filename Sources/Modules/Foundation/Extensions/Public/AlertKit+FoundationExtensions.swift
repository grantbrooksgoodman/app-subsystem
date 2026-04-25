//
//  AlertKit+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/* Proprietary */
import AlertKit

public extension AlertKit.Action {
    // MARK: - Properties

    /// A cancel action using the localized cancel string.
    static var cancelAction: AlertKit.Action {
        .init(
            Localized(SubsystemStringKey.cancel).wrappedValue,
            style: .cancel
        ) {}
    }

    // MARK: - Methods

    /// Returns a cancel action with a custom title.
    static func cancelAction(title: String) -> AlertKit.Action {
        .init(
            title,
            style: .cancel
        ) {}
    }
}
