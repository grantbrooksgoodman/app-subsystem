//
//  FileManagerDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public enum FileManagerDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> FileManager {
        .default
    }
}

public extension DependencyValues {
    var fileManager: FileManager {
        get { self[FileManagerDependency.self] }
        set { self[FileManagerDependency.self] = newValue }
    }
}
