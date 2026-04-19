//
//  FileManager+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension FileManager {
    // MARK: - Properties

    /// The URL of the user's Documents directory.
    var documentsDirectoryURL: URL {
        urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - Methods

    /// Returns the absolute path to a file in the Documents
    /// directory.
    func pathToFileInDocuments(named: String) -> String {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        return documentDirectory.appending("/\(named)")
    }
}
