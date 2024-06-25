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
    protocol BuildInfoOverlayDotIndicatorColorDelegate {
        var developerModeIndicatorDotColor: Color { get }
    }

    struct DefaultBuildInfoOverlayDotIndicatorColorDelegate: BuildInfoOverlayDotIndicatorColorDelegate {
        public let developerModeIndicatorDotColor = Color.orange
    }
}

// swiftlint:enable type_name
