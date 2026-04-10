//
//  BreadcrumbsCaptureDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension AppSubsystem.Delegates {
    @MainActor
    protocol BreadcrumbsCaptureDelegate {
        // MARK: - Properties

        var isCapturing: Bool { get }
        var savesToPhotos: Bool { get }

        // MARK: - Methods

        func setSavesToPhotos(_ savesToPhotos: Bool)

        @discardableResult
        func startCapture() -> Exception?

        @discardableResult
        func stopCapture() -> Exception?
    }
}
