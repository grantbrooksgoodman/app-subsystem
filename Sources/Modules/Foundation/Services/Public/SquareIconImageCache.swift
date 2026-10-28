//
//  SquareIconImageCache.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

/// A namespace for managing the in-memory square icon image cache.
///
/// ``SquareIconView/image(_:)`` stores each rendered icon in this
/// cache, keyed by its configuration, so that repeated requests for
/// the same configuration return the same image without rendering
/// again. The subsystem clears the cache automatically when all
/// cache domains are cleared; call ``clearCache()`` to clear it on
/// demand.
///
/// - SeeAlso: ``SquareIconView``, ``CacheDomain``
public enum SquareIconImageCache {
    // MARK: - Properties

    private static let cachedImagesForEncodedHashes = LockIsolated([String: UIImage]())

    // MARK: - Methods

    /// Removes every cached square icon image.
    public static func clearCache() {
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
