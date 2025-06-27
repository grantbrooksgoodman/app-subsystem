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
}

// swiftlint:enable type_name
