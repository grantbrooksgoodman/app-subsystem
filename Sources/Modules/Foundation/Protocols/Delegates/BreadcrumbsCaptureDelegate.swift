//
//  BreadcrumbsCaptureDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension AppSubsystem.Delegates {
    protocol BreadcrumbsCaptureDelegate {
        // MARK: - Properties

        var isCapturing: Bool { get }

        // MARK: - Methods

        @discardableResult
        func startCapture(saveToPhotos: Bool) -> Exception?

        @discardableResult
        func stopCapture() -> Exception?
    }
}
