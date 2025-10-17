//
//  Array+InternalFoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

extension Array where Element == Any {
    var isValidMetadata: Bool {
        guard count == 4,
              !String(self[0]).isEmpty,
              self[1] is String,
              self[2] is String,
              self[3] is Int else { return false }
        return true
    }
}
