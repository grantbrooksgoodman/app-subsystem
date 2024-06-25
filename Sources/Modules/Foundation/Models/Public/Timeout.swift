//
//  Timeout.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public final class Timeout {
    // MARK: - Dependencies

    @Dependency(\.coreKit.gcd) private var coreGCD: CoreKit.GCD

    // MARK: - Properties

    private var callback: (() -> Void)?
    private var isValid = true

    // MARK: - Object Lifecycle

    public init(
        after duration: Duration,
        callback: @escaping () -> Void
    ) {
        self.callback = callback
        coreGCD.after(duration) {
            guard self.isValid else { return }
            self.invoke()
        }
    }

    deinit {
        cancel()
    }

    // MARK: - Cancellation

    public func cancel() {
        callback = nil
        isValid = false
    }

    // MARK: - Invocation

    private func invoke() {
        callback?()
        cancel()
    }
}
