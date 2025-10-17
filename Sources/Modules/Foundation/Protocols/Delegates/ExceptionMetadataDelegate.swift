//
//  ExceptionMetadataDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension AppSubsystem.Delegates {
    protocol ExceptionMetadataDelegate {
        func isReportable(_ errorCode: String) -> Bool
        func userFacingDescriptor(for descriptor: String) -> String?
    }
}
