//
//  Collection+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension Collection {
    /// Returns an array of transformed elements by applying a throwing closure to each element of the collection concurrently.
    ///
    /// The returned array preserves the relative order of the original collection. Use this method when
    /// you need to perform independent asynchronous work for each element and collect the results,
    /// propagating failures as typed throws rather than `Callback` values.
    ///
    /// - Parameters:
    ///   - failFast: A Boolean value that determines the error-handling strategy. Pass `true` to cancel
    ///     all remaining tasks when any single transformation fails. Pass `false` to allow all tasks to
    ///     complete and throw a compiled exception. The default is `true`.
    ///   - failForEmptyCollection: A Boolean value that indicates whether calling this method on an empty
    ///     collection is treated as a failure. The default is `false`.
    ///   - maxConcurrentOperations: The maximum number of transformations to execute simultaneously. Pass
    ///     `nil` to allow the system to determine the appropriate level of concurrency. The default is `10`.
    ///   - transform: An asynchronous throwing closure that accepts an element of the collection as its parameter
    ///     and returns the transformed value.
    ///
    /// - Returns: The ordered array of transformed values.
    ///
    /// - Throws: An `Exception` if any transformation fails.
    @discardableResult
    func parallelMap<Output>(
        failFast: Bool = true,
        failForEmptyCollection: Bool = false,
        maxConcurrentOperations: Int? = 10,
        transform: @escaping (Element) async throws -> Output // swiftformat:disable all
    ) async throws(Exception) -> [Output] { // swiftformat:enable all
        let parallelMapResult = await parallelMap(
            failFast: failFast,
            failForEmptyCollection: failForEmptyCollection,
            maxConcurrentOperations: maxConcurrentOperations
        ) {
            do {
                return try await .success(transform($0))
            } catch let exception as Exception {
                return .failure(exception)
            } catch {
                return .failure(Exception(
                    error,
                    metadata: .init(sender: self)
                ))
            }
        }

        switch parallelMapResult {
        case let .success(output): return output
        case let .failure(exception): throw exception
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
    ///     complete and throw a compiled exception. The default is `true`.
    ///   - failForEmptyCollection: A Boolean value that indicates whether calling this method on an empty
    ///     collection is treated as a failure. The default is `false`.
    ///   - maxConcurrentOperations: The maximum number of operations to execute simultaneously. Pass
    ///     `nil` to allow the system to determine the appropriate level of concurrency. The default is `10`.
    ///   - perform: An asynchronous throwing closure that accepts an element of the collection as its parameter.
    ///
    /// - Throws: An `Exception` if one or more operations failed.
    func parallelMap(
        failFast: Bool = true,
        failForEmptyCollection: Bool = false,
        maxConcurrentOperations: Int? = 10,
        perform: @escaping (Element) async throws(Exception) -> Void // swiftformat:disable all
    ) async throws(Exception) { // swiftformat:enable all
        if failForEmptyCollection {
            guard !isEmpty else {
                throw Exception(
                    "Collection is empty.",
                    metadata: .init(sender: self)
                )
            }
        }

        let elements = Array(self)
        let result: Exception? = await withTaskGroup(
            of: Exception?.self
        ) { taskGroup in
            var nextIndex = 0

            func enqueueNextTask() {
                guard nextIndex < elements.count else { return }
                let index = nextIndex
                nextIndex += 1

                @LockIsolated var elements: [Element] = elements
                @LockIsolated var perform: (Element) async throws(Exception) -> Void = perform

                taskGroup.addTask {
                    do throws(Exception) {
                        try await perform(elements[index])
                        return nil
                    } catch {
                        return error
                    }
                }
            }

            let initialBatch = Swift.min(
                maxConcurrentOperations ?? elements.count,
                elements.count
            )

            for _ in 0 ..< initialBatch {
                enqueueNextTask()
            }

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

        if let result {
            throw result
        }
    }

    private func parallelMap<Output>(
        failFast: Bool = true,
        failForEmptyCollection: Bool = false,
        maxConcurrentOperations: Int? = 10,
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

            for _ in 0 ..< initialBatch {
                enqueueNextTask()
            }

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
}
