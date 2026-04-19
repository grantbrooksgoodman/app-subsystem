//
//  FileManagerDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// The dependency key that provides a ``FileManager`` instance.
public enum FileManagerDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> FileManager {
        .default
    }
}

public extension DependencyValues {
    /// The shared ``FileManager`` instance.
    var fileManager: FileManager {
        get { self[FileManagerDependency.self] }
        set { self[FileManagerDependency.self] = newValue }
    }
}
