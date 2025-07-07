//
//  Breadcrumbs.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

final class Breadcrumbs {
    // MARK: - Dependencies

    @Dependency(\.build) private var build: Build
    @Dependency(\.coreKit.gcd) private var coreGCD: CoreKit.GCD
    @Dependency(\.breadcrumbsDateFormatter) private var dateFormatter: DateFormatter
    @Dependency(\.fileManager) private var fileManager: FileManager
    @Dependency(\.uiApplication) private var uiApplication: UIApplication

    // MARK: - Properties

    // Array
    private var fileHistory = [String]()

    // Bool
    private(set) var isCapturing = false

    private var uniqueViewsOnly = true
    private var savesToPhotos = true

    // MARK: - Computed Properties

    private var filePath: URL {
        let documents = fileManager.documentsDirectoryURL
        let timeString = dateFormatter.string(from: .now)

        var fileName: String!
        if let leafViewController = uiApplication.keyViewController?.leafViewController {
            fileName = "\(build.codeName)_\(String(type(of: leafViewController))) @ \(timeString).png"
        } else {
            let fileNamePrefix = "\(build.codeName)_\(String(build.buildNumber))"
            let fileNameSuffix = "\(build.milestone.shortString) | \(build.bundleRevision) @ \(timeString).png"
            fileName = fileNamePrefix + fileNameSuffix
        }

        return documents.appending(path: fileName)
    }

    // MARK: - Capture

    @discardableResult
    func startCapture(
        saveToPhotos: Bool = true,
        uniqueViewsOnly doesExclude: Bool = true
    ) -> Exception? {
        guard !isCapturing else {
            return .init("Breadcrumbs capture is already running.", metadata: [self, #file, #function, #line])
        }

        savesToPhotos = saveToPhotos
        uniqueViewsOnly = doesExclude
        isCapturing = true

        func continuallyCapture() {
            guard isCapturing else { return }
            capture()
            coreGCD.after(.seconds(10)) { continuallyCapture() }
        }

        continuallyCapture()
        return nil
    }

    @discardableResult
    func stopCapture() -> Exception? {
        guard isCapturing else {
            return .init("Breadcrumbs capture is not running.", metadata: [self, #file, #function, #line])
        }

        isCapturing = false
        return nil
    }

    // MARK: - Auxiliary

    private func capture() {
        func saveImage() {
            guard let image = uiApplication.snapshot,
                  let pngData = image.pngData() else { return }

            try? pngData.write(to: filePath)

            Observables.breadcrumbsDidCapture.trigger()
            guard savesToPhotos else { return }
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }

        guard Int.random(in: 1 ... 1_000_000) % 3 == 0 else { return }

        if uniqueViewsOnly {
            let viewHierarchyID = uiApplication
                .presentedViews
                .map { String(type(of: $0)) }
                .sorted()
                .joined()
                .encodedHash

            guard !fileHistory.contains(viewHierarchyID) else { return }
            fileHistory.append(viewHierarchyID)
            saveImage()
        } else {
            saveImage()
        }
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
