//
//  Dependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

@propertyWrapper
public struct Dependency<Value>: @unchecked Sendable {
    // MARK: - Properties

    private let initialValues: DependencyValues
    private let keyPath: KeyPath<DependencyValues, Value>

    // MARK: - Init

    public init(_ keyPath: KeyPath<DependencyValues, Value>) {
        initialValues = DependencyValues.current
        self.keyPath = keyPath
    }

    // MARK: - Wrapped Value

    public var wrappedValue: Value { initialValues.merging(DependencyValues.current)[keyPath: keyPath] }
}
