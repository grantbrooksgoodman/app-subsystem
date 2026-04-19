//
//  BreadcrumbsCaptureDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension AppSubsystem.Delegates {
    /// A type that manages periodic screenshot capture for diagnostic
    /// purposes.
    ///
    /// The breadcrumbs system periodically captures snapshots of the
    /// current view hierarchy and writes them to the documents
    /// directory. These snapshots serve as a visual trail – or
    /// "breadcrumbs" – that can help diagnose layout issues, verify
    /// navigation flows, or provide context when investigating bug
    /// reports.
    ///
    /// The subsystem provides a default implementation. Use the
    /// delegate's methods to start and stop capture at appropriate
    /// points in the app lifecycle:
    ///
    /// ```swift
    /// let breadcrumbs = AppSubsystem.delegates.breadcrumbsCapture
    /// breadcrumbs.startCapture()
    ///
    /// // Later, when capture is no longer needed:
    /// breadcrumbs.stopCapture()
    /// ```
    ///
    /// Captured images can optionally be saved to the user's photo
    /// library in addition to the documents directory. Control this
    /// behavior with ``setSavesToPhotos(_:)``.
    ///
    /// - Note: All members of this protocol are isolated to the main actor.
    @MainActor
    protocol BreadcrumbsCaptureDelegate {
        // MARK: - Properties

        /// A Boolean value that indicates whether a capture session
        /// is currently active.
        var isCapturing: Bool { get }

        /// A Boolean value that indicates whether captured
        /// screenshots are saved to the user's photo library.
        var savesToPhotos: Bool { get }

        // MARK: - Methods

        /// Sets whether captured screenshots are saved to the user's
        /// photo library.
        ///
        /// - Parameter savesToPhotos: Pass `true` to save captures
        ///   to both the documents directory and the photo library,
        ///   or `false` to save to the documents directory only.
        func setSavesToPhotos(_ savesToPhotos: Bool)

        /// Starts a periodic capture session.
        ///
        /// While the session is active, the system periodically
        /// captures a snapshot of the current view hierarchy. Each
        /// unique view configuration is captured at most once per
        /// session.
        ///
        /// - Returns: An ``Exception`` if a capture session is
        ///   already running, or `nil` on success.
        @discardableResult
        func startCapture() -> Exception?

        /// Stops the current capture session.
        ///
        /// Any in-progress capture completes, but no further
        /// snapshots are taken.
        ///
        /// - Returns: An ``Exception`` if no capture session is
        ///   currently running, or `nil` on success.
        @discardableResult
        func stopCapture() -> Exception?
    }
}
