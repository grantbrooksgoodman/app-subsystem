//
//  AppException.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public struct AppException: Hashable {
    // MARK: - Properties

    public let errorCode: String

    // MARK: - Init

    public init(_ errorCode: String) {
        self.errorCode = errorCode
    }
}
