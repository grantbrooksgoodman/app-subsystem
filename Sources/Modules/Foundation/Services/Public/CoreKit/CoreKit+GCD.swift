//
//  CoreKit+GCD.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension CoreKit {
    struct GCD: Sendable {
        // MARK: - Dependencies

        @Dependency(\.mainQueue) private var mainQueue: DispatchQueue

        // MARK: - Properties

        static let shared = GCD()

        // MARK: - Init

        private init() {}

        // MARK: - Methods

        public func after(
            _ duration: Duration,
            do effect: @escaping @Sendable () -> Void
        ) {
            mainQueue.asyncAfter(deadline: .now() + .milliseconds(.init(duration.milliseconds))) {
                effect()
            }
        }

        public func syncOnMain(
            do effect: @escaping @Sendable () -> Void
        ) {
            guard Thread.isMainThread else {
                return mainQueue.sync { effect() }
            }

            effect()
        }
    }
}
