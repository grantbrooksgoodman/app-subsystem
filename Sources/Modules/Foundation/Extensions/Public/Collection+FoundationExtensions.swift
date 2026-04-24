//
//  Collection+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension Collection {
    /// Returns an array of transformed elements by applying a closure to each element of the collection concurrently.
    ///
    /// The returned array preserves the relative order of the original collection. Use this method when
    /// you need to perform independent asynchronous work for each element and collect the results.
    ///
    /// - Parameters:
    ///   - failFast: A Boolean value that determines the error-handling strategy. Pass `true` to cancel
    ///     all remaining tasks when any single transformation fails. Pass `false` to allow all tasks to
    ///     complete and return a compiled exception. The default is `true`.
    ///   - failForEmptyCollection: A Boolean value that indicates whether calling this method on an empty
    ///     collection is treated as a failure. The default is `false`.
    ///   - maxConcurrentOperations: The maximum number of transformations to execute simultaneously. Pass
    ///     `nil` to allow the system to determine the appropriate level of concurrency. The default is `15`.
    ///   - transform: An asynchronous closure that accepts an element of the collection as its parameter
    ///     and returns a `Callback` containing the transformed value.
    ///
    /// - Returns: A `Callback` containing the ordered array of transformed values, or the exception
    ///   that caused the operation to fail.
    func parallelMap<Output>(
        failFast: Bool = true,
        failForEmptyCollection: Bool = false,
        maxConcurrentOperations: Int? = 15,
        transform: @escaping (Element) async -> Callback<Output, Exception>
    ) async -> Callback<[Output], Exception> {
        if failForEmptyCollection {
            guard !isEmpty else {
                return .failure(.init(
                    "Collection is empty.",
                    metadata: .init(sender: self)
                ))
            }
        }

        let elements = Array(self)
        return await withTaskGroup(
            of: (Int, Callback<Output, Exception>).self
        ) { taskGroup in
            var results: [Output?] = Array(
                repeating: nil,
                count: elements.count
            )

            var nextIndex = 0

            func enqueueNextTask() {
                guard nextIndex < elements.count else { return }
                let index = nextIndex
                nextIndex += 1

                @LockIsolated var elements: [Element] = elements
                @LockIsolated var transform: (Element) async -> Callback<Output, Exception> = transform

                taskGroup.addTask {
                    await (
                        index,
                        transform(elements[index])
                    )
                }
            }

            let initialBatch = Swift.min(
                maxConcurrentOperations ?? elements.count,
                elements.count
            )

            for _ in 0 ..< initialBatch { enqueueNextTask() }

            var exceptions = [Exception]()
            while let (index, result) = await taskGroup.next() {
                switch result {
                case let .success(value):
                    results[index] = value
                    enqueueNextTask()

                case let .failure(exception):
                    if failFast {
                        taskGroup.cancelAll()
                        return Callback<[Output], Exception>.failure(exception)
                    }

                    exceptions.append(exception)
                    enqueueNextTask()
                }
            }

            if let exception = exceptions.compiledException {
                return .failure(exception)
            }

            guard results.allSatisfy({ $0 != nil }) else {
                return .failure(.init(
                    "Parallel map results were incomplete.",
                    metadata: .init(sender: self)
                ))
            }

            return .success(results.compactMap(\.self))
        }
    }

    /// Performs an operation on each element of the collection concurrently.
    ///
    /// Use this method when you need to perform independent asynchronous work for each element
    /// without collecting transformed results.
    ///
    /// - Parameters:
    ///   - failFast: A Boolean value that determines the error-handling strategy. Pass `true` to cancel
    ///     all remaining tasks when any single operation fails. Pass `false` to allow all tasks to
    ///     complete and return a compiled exception. The default is `true`.
    ///   - failForEmptyCollection: A Boolean value that indicates whether calling this method on an empty
    ///     collection is treated as a failure. The default is `false`.
    ///   - maxConcurrentOperations: The maximum number of operations to execute simultaneously. Pass
    ///     `nil` to allow the system to determine the appropriate level of concurrency. The default is `15`.
    ///   - perform: An asynchronous closure that accepts an element of the collection as its parameter
    ///     and returns an optional exception indicating whether the operation succeeded.
    ///
    /// - Returns: A compiled exception if one or more operations failed; otherwise, `nil`.
    func parallelMap(
        failFast: Bool = true,
        failForEmptyCollection: Bool = false,
        maxConcurrentOperations: Int? = 15,
        perform: @escaping (Element) async -> Exception?
    ) async -> Exception? {
        if failForEmptyCollection {
            guard !isEmpty else {
                return .init(
                    "Collection is empty.",
                    metadata: .init(sender: self)
                )
            }
        }

        let elements = Array(self)
        return await withTaskGroup(
            of: Exception?.self
        ) { taskGroup in
            var nextIndex = 0

            func enqueueNextTask() {
                guard nextIndex < elements.count else { return }
                let index = nextIndex
                nextIndex += 1

                @LockIsolated var elements: [Element] = elements
                @LockIsolated var perform: (Element) async -> Exception? = perform

                taskGroup.addTask {
                    await perform(elements[index])
                }
            }

            let initialBatch = Swift.min(
                maxConcurrentOperations ?? elements.count,
                elements.count
            )

            for _ in 0 ..< initialBatch { enqueueNextTask() }

            var exceptions = [Exception]()
            while let exception = await taskGroup.next() {
                if let exception {
                    guard !failFast else {
                        taskGroup.cancelAll()
                        return exception
                    }

                    exceptions.append(exception)
                }

                enqueueNextTask()
            }

            return exceptions.compiledException
        }
    }
}
