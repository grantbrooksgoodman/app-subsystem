//
//  SquareIconImageCache.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

enum SquareIconImageCache {
    // MARK: - Properties

    private static let cachedImagesForEncodedHashes = LockIsolated([String: UIImage]())

    // MARK: - Methods

    static func clearCache() {
        cachedImagesForEncodedHashes.wrappedValue = [:]
    }

    static func image(forEncodedHash encodedHash: String) -> UIImage? {
        cachedImagesForEncodedHashes.projectedValue[encodedHash]
    }

    static func setImage(
        _ image: UIImage?,
        forEncodedHash encodedHash: String
    ) {
        cachedImagesForEncodedHashes.projectedValue[encodedHash] = image
    }
}
