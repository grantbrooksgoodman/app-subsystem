//
//  ExceptionMetadataDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension AppSubsystem.Delegates {
    /// A type that provides app-specific metadata for
    /// exception handling.
    ///
    /// Conform to `ExceptionMetadataDelegate` to control which
    /// exceptions are reported and to supply user-facing descriptions
    /// for known error conditions. Pass the conforming instance to
    /// ``AppSubsystem`` during initialization.
    ///
    /// - SeeAlso: ``Exception``
    protocol ExceptionMetadataDelegate {
        /// Returns a Boolean value indicating whether the exception
        /// with the given error code should be reported.
        ///
        /// - Parameter errorCode: The exception's error code.
        ///
        /// - Returns: `true` if the exception can be reported;
        ///   otherwise, `false`.
        func isReportable(_ errorCode: String) -> Bool

        /// Returns a localized, user-facing description for the given
        /// developer-facing descriptor, or `nil` if no mapping exists.
        ///
        /// - Parameter descriptor: The exception's developer-facing
        ///   descriptor.
        ///
        /// - Returns: A user-appropriate string, or `nil`.
        func userFacingDescriptor(for descriptor: String) -> String?
    }
}
