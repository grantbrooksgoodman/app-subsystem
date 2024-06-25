//
//  AnyTask.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

final class AnyTask {
    // MARK: - Properties

    public let options: Options

    public var isCancelled: Bool { isCancelledBlock() }

    private let assertionFailureHandler: (@autoclosure () -> String, StaticString, UInt) -> Void
    private let hashValueBlock: () -> Int
    private let isCancelledBlock: () -> Bool
    private let onCancel: () -> Void

    // MARK: - Init

    init(
        _ task: Task<some Any, some Any>,
        options: Options,
        assertionFailureHandler: @escaping (@autoclosure () -> String, StaticString, UInt) -> Void
    ) {
        self.options = options
        hashValueBlock = { task.hashValue }
        isCancelledBlock = { task.isCancelled }
        onCancel = task.cancel
        self.assertionFailureHandler = assertionFailureHandler
    }

    public convenience init(
        _ task: Task<some Any, some Any>,
        options: Options = .default
    ) {
        self.init(
            task,
            options: options,
            assertionFailureHandler: assertionFailure
        )
    }

    // MARK: - Object Lifecycle

    deinit {
        guard !isCancelled else { return }
        cancel()
    }

    // MARK: - Cancel

    public func cancel() {
        guard !isCancelled else { return assertCancellationIfNeeded() }
        onCancel()
    }

    // MARK: - Auxiliary

    private func assertCancellationIfNeeded() {
        guard options.contains(.assertOnOverCancellation) else { return }
        assertionFailureHandler(
            "Task was cancelled more than once",
            #file,
            #line
        )
    }
}

extension AnyTask {
    public struct Options: OptionSet {
        // MARK: - Properties

        public static let automaticallyCancelOnDeinit: Self = .init(rawValue: 1 << 0)
        public static let assertOnOverCancellation: Self = .init(rawValue: 1 << 1)
        public static let `default`: Self = [.automaticallyCancelOnDeinit]

        public let rawValue: Int

        // MARK: - Init

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
}

extension AnyTask: Hashable {
    public static func == (lhs: AnyTask, rhs: AnyTask) -> Bool { lhs.hashValue == rhs.hashValue }
    public func hash(into hasher: inout Hasher) { hasher.combine(hashValueBlock()) }
}

extension Task {
    func erased(options: AnyTask.Options = .default) -> AnyTask { .init(self, options: options) }

    @discardableResult
    func store<Collection: RangeReplaceableCollection>(
        in collection: inout Collection,
        options: AnyTask.Options = .default
    ) -> AnyTask where Collection.Element == AnyTask {
        let task = erased(options: options)
        collection.append(task)
        return task
    }

    @discardableResult
    func store(
        in set: inout Set<AnyTask>,
        options: AnyTask.Options = .default
    ) -> (inserted: Bool, memberAfterInsert: AnyTask) {
        set.insert(erased(options: options))
    }
}
