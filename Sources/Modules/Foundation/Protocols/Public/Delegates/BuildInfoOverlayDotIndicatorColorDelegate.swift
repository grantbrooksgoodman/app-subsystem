//
//  BuildInfoOverlayDotIndicatorColorDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

// swiftlint:disable type_name
public extension AppSubsystem.Delegates {
    /// A type that provides the color for the Developer Mode indicator
    /// dot in the build info overlay.
    ///
    /// When Developer Mode is enabled, the build info overlay displays
    /// a small colored dot to signal that the mode is active. By
    /// default, this dot is orange. Conform to this protocol to
    /// supply a custom color that better suits your app's
    /// visual design:
    ///
    /// ```swift
    /// struct AppBuildInfoDotColor: AppSubsystem.Delegates.BuildInfoOverlayDotIndicatorColorDelegate {
    ///     var developerModeIndicatorDotColor: Color { .mint }
    /// }
    /// ```
    ///
    /// Register your conformance through
    /// ``AppSubsystem/Delegates/register(breadcrumbsCaptureDelegate:buildInfoOverlayDotIndicatorColorDelegate:cacheDomainListDelegate:devModeAppActionDelegate:exceptionMetadataDelegate:forcedUpdateModalDelegate:loggerDomainSubscriptionDelegate:permanentUserDefaultsKeyDelegate:)``
    /// or
    /// ``AppSubsystem/Delegates/registerBuildInfoOverlayDotIndicatorColorDelegate(_:)``.
    ///
    /// - Note: The dot color temporarily changes to red when a
    ///   breadcrumbs capture occurs, then restores to the color
    ///   returned by this delegate.
    protocol BuildInfoOverlayDotIndicatorColorDelegate {
        /// The color to use for the Developer Mode indicator dot.
        var developerModeIndicatorDotColor: Color { get }
    }
}

// swiftlint:enable type_name
