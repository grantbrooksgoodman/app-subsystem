//
//  CoreKitDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public enum CoreKitDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> CoreKit {
        @MainActorIsolated var coreKit = CoreKit(
            gcd: .shared,
            hud: .shared,
            ui: .shared,
            utils: .shared
        )

        return coreKit
    }
}

public extension DependencyValues {
    var coreKit: CoreKit {
        get { self[CoreKitDependency.self] }
        set { self[CoreKitDependency.self] = newValue }
    }
}
