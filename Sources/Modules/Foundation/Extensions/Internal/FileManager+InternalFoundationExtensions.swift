//
//  FileManager+InternalFoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

extension FileManager {
    static let applicationSupportDirectoryURL: URL = {
        @Dependency(\.fileManager) var fileManager: FileManager
        return (try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? URL.applicationSupportDirectory
    }()
}
