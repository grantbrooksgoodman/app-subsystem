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
///
/// ## Thread Safety
///
/// All state transitions are protected by a single lock, making
/// `Timeout` safe to use from any thread or concurrency context.
/// The callback is invoked *outside* the lock to avoid holding it
/// during arbitrary user code.
public final class Timeout: Sendable {
    // MARK: - Types

    private enum State {
        case cancelled
        case fired
        case pending(@Sendable () -> Void)
    }

    // MARK: - Properties

    private let _state = LockIsolated(State.cancelled)
    private let _task = LockIsolated<Task<Void, Never>?>(nil)

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
        callback: @escaping @Sendable () -> Void
    ) {
        _state.wrappedValue = .pending(callback)

        let state = _state
        _task.wrappedValue = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard self != nil else { return }

            let action: (@Sendable () -> Void)? = state.projectedValue.withValue {
                guard case let .pending(callback) = $0 else { return nil }
                $0 = .fired
                return callback
            }

            action?()
        }
    }

    deinit {
        cancel()
    }

    // MARK: - Cancellation

    /// Cancels the timeout, preventing the callback from firing.
    ///
    /// This method atomically transitions the state and releases the
    /// callback closure. The underlying task is also cooperatively
    /// cancelled so it does not linger for the remaining duration.
    ///
    /// It is safe to call `cancel()` multiple times or from any
    /// thread.
    public func cancel() {
        _state.projectedValue.withValue {
            guard case .pending = $0 else { return }
            $0 = .cancelled
        }

        _task.wrappedValue?.cancel()
        _task.wrappedValue = nil
    }
}
