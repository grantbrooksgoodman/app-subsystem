//
//  BuildDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public enum BuildDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> Build {
        var developerModeEnabled = false
        @Persistent(.developerModeEnabled) var defaultsValue: Bool?
        if let value = defaultsValue {
            developerModeEnabled = AppSubsystem.bundle.buildMilestone == .generalRelease ? false : value
            defaultsValue = developerModeEnabled
        }

        return .init(
            appStoreReleaseVersion: AppSubsystem.bundle.appStoreReleaseVersion,
            codeName: AppSubsystem.bundle.codeName,
            developerModeEnabled: developerModeEnabled,
            dmyFirstCompileDateString: AppSubsystem.bundle.dmyFirstCompileDateString,
            finalName: AppSubsystem.bundle.finalName,
            loggingEnabled: AppSubsystem.bundle.loggingEnabled,
            milestone: AppSubsystem.bundle.buildMilestone,
            timebombActive: AppSubsystem.bundle.timebombActive
        )
    }
}

public extension DependencyValues {
    var build: Build {
        get { self[BuildDependency.self] }
        set { self[BuildDependency.self] = newValue }
    }
}
