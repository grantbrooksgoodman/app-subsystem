//
//  JSONDependencies.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// The dependency key that provides a ``JSONDecoder`` instance.
public enum JSONDecoderDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> JSONDecoder {
        .init()
    }
}

/// The dependency key that provides a ``JSONEncoder`` instance.
public enum JSONEncoderDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> JSONEncoder {
        .init()
    }
}

public extension DependencyValues {
    /// The shared ``JSONDecoder`` instance.
    var jsonDecoder: JSONDecoder {
        get { self[JSONDecoderDependency.self] }
        set { self[JSONDecoderDependency.self] = newValue }
    }

    /// The shared ``JSONEncoder`` instance.
    var jsonEncoder: JSONEncoder {
        get { self[JSONEncoderDependency.self] }
        set { self[JSONEncoderDependency.self] = newValue }
    }
}
