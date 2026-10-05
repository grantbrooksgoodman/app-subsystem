//
//  CoreKitDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// The dependency key that provides a ``CoreKit`` instance.
public enum CoreKitDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> CoreKit {
        // swiftformat:disable all
        @MainActorIsolated var coreKit = CoreKit(
            gcd: .shared,
            hud: .shared,
            ui: .shared,
            utils: .shared
        )
        
        return coreKit // swiftformat:enable all
    }
}

public extension DependencyValues {
    /// The shared ``CoreKit`` instance.
    var coreKit: CoreKit {
        get { self[CoreKitDependency.self] }
        set { self[CoreKitDependency.self] = newValue }
    }
}
