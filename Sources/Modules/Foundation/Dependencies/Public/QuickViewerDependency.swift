//
//  QuickViewerDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// The dependency key that provides a ``QuickViewer`` instance.
public enum QuickViewerDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> QuickViewer {
        @MainActorIsolated var quickViewer = QuickViewer()
        return quickViewer
    }
}

public extension DependencyValues {
    /// The shared ``QuickViewer`` instance.
    var quickViewer: QuickViewer {
        get { self[QuickViewerDependency.self] }
        set { self[QuickViewerDependency.self] = newValue }
    }
}
