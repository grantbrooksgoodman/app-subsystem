//
//  URLSessionDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public enum URLSessionDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> URLSession {
        .shared
    }
}

public extension DependencyValues {
    var urlSession: URLSession {
        get { self[URLSessionDependency.self] }
        set { self[URLSessionDependency.self] = newValue }
    }
}
