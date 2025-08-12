//
//  Breadcrumbs.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

@MainActor
final class Breadcrumbs: @preconcurrency AppSubsystem.Delegates.BreadcrumbsCaptureDelegate {
    // MARK: - Dependencies

    @Dependency(\.build) private var build: Build
    @Dependency(\.breadcrumbsDateFormatter) private var dateFormatter: DateFormatter
    @Dependency(\.fileManager) private var fileManager: FileManager
    @Dependency(\.uiApplication) private var uiApplication: UIApplication

    // MARK: - Properties

    nonisolated static let shared = Breadcrumbs()

    private(set) var savesToPhotos = true

    private var captureTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var isCapturing: Bool { captureTask != nil }

    private var captureHistory: Set<String> {
        get { @Persistent(.breadcrumbsCaptureHistory) var persistedValue: Set<String>?; return persistedValue ?? .init() }
        set { @Persistent(.breadcrumbsCaptureHistory) var persistedValue: Set<String>?; persistedValue = newValue }
    }

    private var filePath: URL {
        let documents = fileManager.documentsDirectoryURL
        let timeString = dateFormatter.string(from: .now)

        var fileName: String!
        if let leafViewController = uiApplication.keyViewController?.leafViewController {
            fileName = "\(build.codeName)_\(leafViewController.descriptor) @ \(timeString).png"
        } else {
            let fileNamePrefix = "\(build.codeName)_\(String(build.buildNumber))"
            let fileNameSuffix = "\(build.milestone.shortString) | \(build.bundleRevision) @ \(timeString).png"
            fileName = fileNamePrefix + fileNameSuffix
        }

        return documents.appending(path: fileName)
    }

    // MARK: - Object Lifecycle

    private nonisolated init() {}

    deinit {
        captureTask?.cancel()
        captureTask = nil
    }

    // MARK: - Capture

    @discardableResult
    func startCapture() -> Exception? {
        guard !isCapturing else {
            return .init(
                "Breadcrumbs capture is already running.",
                metadata: [self, #file, #function, #line]
            )
        }

        captureTask = Task { @MainActor in
            while !Task.isCancelled,
                  isCapturing {
                capture()
                try? await Task.sleep(for: .seconds(10))
            }
        }

        return nil
    }

    @discardableResult
    func stopCapture() -> Exception? {
        guard isCapturing else {
            return .init(
                "Breadcrumbs capture is not running.",
                metadata: [self, #file, #function, #line]
            )
        }

        captureTask?.cancel()
        captureTask = nil
        return nil
    }

    // MARK: - Set Saves to Photos

    func setSavesToPhotos(_ savesToPhotos: Bool) {
        self.savesToPhotos = savesToPhotos
    }

    // MARK: - Auxiliary

    private func capture() {
        guard Int.random(in: 1 ... 1_000_000) % 3 == 0 else { return }

        let viewHierarchyID = (uiApplication
            .presentedViews
            .map(\.descriptor) + ["\(build.buildNumber)\(build.milestone.shortString)"])
            .sorted()
            .joined()
            .encodedHash

        var captureHistory = captureHistory
        guard !captureHistory.contains(viewHierarchyID),
              let image = uiApplication.snapshot,
              let pngData = image.pngData() else { return }

        captureHistory.insert(viewHierarchyID)
        self.captureHistory = captureHistory

        let filePath = filePath; Task.detached { try? pngData.write(to: filePath) }
        Observables.breadcrumbsDidCapture.trigger()

        guard savesToPhotos else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

/* MARK: DateFormatter Dependency */

private enum BreadcrumbsDateFormatterDependency: DependencyKey {
    static func resolve(_: DependencyValues) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        return formatter
    }
}

private extension DependencyValues {
    var breadcrumbsDateFormatter: DateFormatter {
        get { self[BreadcrumbsDateFormatterDependency.self] }
        set { self[BreadcrumbsDateFormatterDependency.self] = newValue }
    }
}
