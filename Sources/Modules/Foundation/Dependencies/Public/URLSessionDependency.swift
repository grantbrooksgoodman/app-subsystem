//
//  URLSessionDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// The dependency key that provides a ``URLSession`` instance.
public enum URLSessionDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> URLSession {
        .shared
    }
}

public extension DependencyValues {
    /// The shared ``URLSession`` instance.
    var urlSession: URLSession {
        get { self[URLSessionDependency.self] }
        set { self[URLSessionDependency.self] = newValue }
    }
}
