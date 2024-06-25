//
//  ObservedDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

@propertyWrapper
public struct ObservedDependency<Value>: DynamicProperty where Value: ObservableObject {
    // MARK: - Properties

    @ObservedObject private var value: Value

    // MARK: - Computed Properties

    public var projectedValue: ObservedObject<Value>.Wrapper { $value }
    public var wrappedValue: Value { value }

    // MARK: - Init

    public init(_ keyPath: KeyPath<DependencyValues, Value>) {
        value = DependencyValues.current[keyPath: keyPath]
    }
}
