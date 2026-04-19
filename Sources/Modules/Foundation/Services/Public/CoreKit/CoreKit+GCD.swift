//
//  CoreKit+GCD.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension CoreKit {
    /// Grand Central Dispatch helpers for main-thread execution.
    struct GCD: Sendable {
        // MARK: - Dependencies

        @Dependency(\.mainQueue) private var mainQueue: DispatchQueue

        // MARK: - Properties

        static let shared = GCD()

        // MARK: - Init

        private init() {}

        // MARK: - Methods

        /// Executes the given closure synchronously on the main
        /// thread.
        ///
        /// If the caller is already on the main thread, the closure
        /// runs immediately. Otherwise, it is dispatched
        /// synchronously to the main queue.
        ///
        /// - Parameter effect: The closure to execute on the main
        ///   thread.
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
