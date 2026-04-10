//
//  Timeout.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public final class Timeout: @unchecked Sendable {
    // MARK: - Properties

    private var callback: (() -> Void)?
    private var isValid = true

    // MARK: - Object Lifecycle

    public init(
        after duration: Duration,
        callback: @escaping () -> Void
    ) {
        self.callback = callback
        Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard let self,
                  self.isValid else { return }
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
