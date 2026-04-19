//
//  QuickViewer.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import QuickLook

/// A convenience wrapper around `QLPreviewController` for previewing
/// one or more files.
///
/// `QuickViewer` manages the data source and delegate requirements of
/// QuickLook, letting you present a file preview with a single call:
///
/// ```swift
/// @Dependency(\.quickViewer) var quickViewer: QuickViewer
///
/// quickViewer.preview(
///     filesAtPaths: [documentPath],
///     title: "Report"
/// )
/// ```
///
/// When multiple paths are provided, the user can swipe between
/// previews. Use ``onDismiss(_:)`` to perform cleanup when the
/// preview is closed.
///
/// - SeeAlso: ``QuickViewerDependency``
public final class QuickViewer: NSObject, QLPreviewControllerDataSource, @preconcurrency QLPreviewControllerDelegate {
    // MARK: - Types

    private final class PreviewItem: NSObject, QLPreviewItem {
        // MARK: - Properties

        var previewItemTitle: String?
        var previewItemURL: URL?

        // MARK: - Init

        init(
            title: String? = nil,
            url: URL? = nil
        ) {
            previewItemTitle = title
            previewItemURL = url
        }
    }

    // MARK: - Properties

    private var filePaths = [String]()
    private var previewItemTitle: String?
    private var _onDismiss: (() -> Void)?

    // MARK: - Preview

    /// Presents a QuickLook preview for the files at the given paths.
    ///
    /// Empty paths are filtered out automatically. When multiple
    /// valid paths are provided, the user can swipe between previews.
    ///
    /// - Parameters:
    ///   - paths: The file paths to preview.
    ///   - startingIndex: The index of the file to display first.
    ///     The default is `0`.
    ///   - title: An optional title displayed in the preview's
    ///     navigation bar.
    ///   - embedded: Pass `true` to wrap the preview controller in
    ///     a `UINavigationController` before presenting.
    ///
    /// - Returns: An ``Exception`` if no valid paths are provided,
    ///   or `nil` on success.
    @discardableResult
    public func preview(
        filesAtPaths paths: [String],
        startingIndex: Int = 0,
        title: String? = nil,
        embedded: Bool = false
    ) -> Exception? {
        @Dependency(\.coreKit.ui) var coreUI: CoreKit.UI

        let paths = paths.filter { !$0.isEmpty }
        guard !paths.isEmpty else {
            return .init(
                "No file to preview.",
                metadata: .init(sender: self)
            )
        }

        let previewController = QLPreviewController()
        previewController.dataSource = self
        previewController.delegate = self

        if paths.count > startingIndex {
            previewController.currentPreviewItemIndex = startingIndex
        }

        filePaths = paths
        previewItemTitle = title

        if !UIApplication.isFullyV26Compatible {
            StatusBar.overrideStyle(.lightContent)
        }

        coreUI.present(previewController, embedded: embedded)

        return nil
    }

    // MARK: - On Dismiss

    /// Registers a closure to execute when the preview is dismissed.
    ///
    /// The closure is called once and then cleared. Calling this
    /// method again replaces any previously registered closure.
    ///
    /// - Parameter perform: The closure to execute on dismissal.
    public func onDismiss(_ perform: @escaping () -> Void) {
        _onDismiss = perform
    }

    // MARK: - QLPreviewControllerDataSource Conformance

    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        filePaths.count
    }

    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard let filePath = filePaths.itemAt(index) else { return PreviewItem() }
        let amendedPath = filePath.removingOccurrences(of: ["file:///", "file://", "file:/"])
        return PreviewItem(title: previewItemTitle, url: URL(filePath: amendedPath))
    }

    // MARK: - QLPreviewControllerDelegate Conformance

    public func previewControllerDidDismiss(_ controller: QLPreviewController) {
        StatusBar.restoreStyle()

        _onDismiss?()
        _onDismiss = nil
    }
}
