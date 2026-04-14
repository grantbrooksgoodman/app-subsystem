//
//  DevModeAction.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public struct DevModeAction: Sendable {
    // MARK: - Properties

    public let isDestructive: Bool
    public let perform: @Sendable () -> Void
    public let title: String

    // MARK: - Init

    public init(
        title: String,
        isDestructive: Bool = false,
        perform: @escaping @Sendable () -> Void
    ) {
        self.title = title
        self.isDestructive = isDestructive
        self.perform = perform
    }

    // MARK: - Equality Comparison

    public func metadata(isEqual action: DevModeAction) -> Bool {
        guard title == action.title,
              isDestructive == action.isDestructive else { return false }
        return true
    }

    public func metadata(isEqual data: (title: String, isDestructive: Bool)) -> Bool {
        guard title == data.title,
              isDestructive == data.isDestructive else { return false }
        return true
    }
}
