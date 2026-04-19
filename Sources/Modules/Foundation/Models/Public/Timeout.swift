//
//  Timeout.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// A cancellable delayed callback that fires once after a specified
/// duration.
///
/// Use `Timeout` to schedule a one-shot action that can be cancelled
/// before it fires:
///
/// ```swift
/// let timeout = Timeout(after: .seconds(5)) {
///     showSessionExpiredAlert()
/// }
///
/// // Cancel if the user acts in time:
/// timeout.cancel()
/// ```
///
/// The callback is invoked at most once. After it fires – or after
/// ``cancel()`` is called – the timeout is invalidated and the
/// callback reference is released. The timeout is also cancelled
/// automatically when the instance is deallocated, so retaining or
/// releasing the `Timeout` controls its lifetime.
public final class Timeout: @unchecked Sendable {
    // MARK: - Properties

    private var callback: (() -> Void)?
    private var isValid = true

    // MARK: - Object Lifecycle

    /// Creates a timeout that invokes the callback after the given
    /// duration.
    ///
    /// The callback is scheduled immediately upon initialization. To
    /// prevent it from firing, call ``cancel()`` or release the
    /// `Timeout` instance.
    ///
    /// - Parameters:
    ///   - duration: The delay before the callback is invoked.
    ///   - callback: The closure to execute when the timeout elapses.
    public init(
        after duration: Duration,
        callback: @escaping () -> Void
    ) {
        self.callback = callback
        Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard let self,
                  isValid else { return }
            invoke()
        }
    }

    deinit {
        cancel()
    }

    // MARK: - Cancellation

    /// Cancels the timeout, preventing the callback from firing.
    ///
    /// Calling this method releases the callback closure immediately.
    /// It is safe to call `cancel()` multiple times.
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
