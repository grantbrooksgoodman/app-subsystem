//
//  QuickViewerDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public enum QuickViewerDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> QuickViewer {
        @MainActorIsolated var quickViewer = QuickViewer()
        return quickViewer
    }
}

public extension DependencyValues {
    var quickViewer: QuickViewer {
        get { self[QuickViewerDependency.self] }
        set { self[QuickViewerDependency.self] = newValue }
    }
}
