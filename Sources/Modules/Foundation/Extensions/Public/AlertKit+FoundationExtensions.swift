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

    static var cancelAction: AlertKit.Action {
        .init(
            AppSubsystem.delegates.localizedStrings.cancel,
            style: .cancel
        ) {}
    }

    // MARK: - Methods

    static func cancelAction(title: String) -> AlertKit.Action {
        .init(
            title,
            style: .cancel
        ) {}
    }
}
