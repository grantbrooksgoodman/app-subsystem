//
//  GroupedListView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/* Proprietary */
import ComponentKit

/// A view that renders a list of rows in a rounded, grouped style with
/// optional header and footer text.
///
/// `GroupedListView` arranges an array of
/// ``ListRowView/Configuration`` values into a visually cohesive group
/// separated by dividers, similar to a Settings-style list:
///
/// ```swift
/// GroupedListView(
///     [
///         .init(.button { showProfile() }, innerText: "Profile"),
///         .init(.switch(isToggled: $notificationsOn), innerText: "Notifications"),
///     ],
///     headerText: "Account"
/// )
/// ```
///
/// When individual row configurations supply their own header or
/// footer text, the view concatenates them automatically unless you
/// provide explicit `headerText` or `footerText` values at
/// initialization.
///
/// - SeeAlso: ``ListRowView``, ``ListRowView/Configuration``
public struct GroupedListView: View {
    // MARK: - Constants Accessors

    private typealias Floats = FoundationConstants.CGFloats.GroupedListView

    // MARK: - Properties

    private let footerText: String?
    private let headerText: String?
    private let rows: [ListRowView.Configuration]

    // MARK: - Init

    /// Creates a grouped list from the given row configurations.
    ///
    /// - Parameters:
    ///   - rows: The row configurations to display.
    ///   - headerText: An optional header string displayed above the
    ///     group. When `nil`, the view concatenates any header text
    ///     from the individual row configurations.
    ///   - footerText: An optional footer string displayed below the
    ///     group. When `nil`, the view concatenates any footer text
    ///     from the individual row configurations.
    @MainActor
    public init(
        _ rows: [ListRowView.Configuration],
        headerText: String? = nil,
        footerText: String? = nil
    ) {
        self.rows = rows.strippingMetadata
        self.headerText = headerText ?? rows.concatenatedHeaderText
        self.footerText = footerText ?? rows.concatenatedFooterText
    }

    // MARK: - View

    public var body: some View {
        if headerText != nil || footerText != nil {
            VStack(alignment: .leading) {
                if let headerText {
                    Components.text(
                        headerText.uppercased(),
                        font: .system(scale: .custom(Floats.headerLabelSystemFontScale)),
                        foregroundColor: .subtitleText
                    )
                    .padding(.horizontal, Floats.headerLabelHorizontalPadding)
                }

                listView

                if let footerText {
                    Components.text(
                        footerText,
                        font: .system(scale: .custom(Floats.footerLabelSystemFontScale)),
                        foregroundColor: .subtitleText
                    )
                    .padding(.horizontal, Floats.footerLabelHorizontalPadding)
                    .padding(.top, 1)
                }
            }
        } else {
            listView
        }
    }

    private var listView: some View {
        VStack(spacing: 0) {
            ForEach(0 ..< rows.count, id: \.self) { index in
                ListRowView(rows[index])
                    .if(index != rows.count - 1) {
                        $0
                            .overlay(
                                Divider()
                                    .padding(
                                        .leading,
                                        rows[index].imageView == nil ? Floats.dividerLeadingPadding : Floats.dividerAlternateLeadingPadding
                                    )
                                    .if(UIApplication.isFullyV26Compatible) { $0.padding(.trailing, Floats.dividerTrailingPadding) },
                                alignment: .bottom
                            )
                    }
            }
        }
        .cornerRadius(Floats.cornerRadius)
    }
}

private extension [ListRowView.Configuration] {
    var concatenatedFooterText: String? {
        let countGreaterThanOne = count > 1
        let concatenated = reduce(into: [String]()) { partialResult, configuration in
            if let footerText = configuration.footerText {
                let string = countGreaterThanOne ? "\(configuration.innerText.uppercased())\n\(footerText)" : footerText
                partialResult.append(string)
            }
        }.joined(separator: "\n\n").trimmingTrailingNewlines.trimmingBorderedWhitespace

        guard !concatenated.isBlank else { return nil }
        return concatenated
    }

    var concatenatedHeaderText: String? {
        let concatenated = reduce(into: [String]()) { partialResult, configuration in
            if let headerText = configuration.headerText {
                partialResult.append(headerText)
            }
        }.joined(separator: " / ").trimmingTrailingNewlines.trimmingBorderedWhitespace

        guard !concatenated.isBlank else { return nil }
        return concatenated
    }

    @MainActor
    var strippingMetadata: [ListRowView.Configuration] {
        reduce(into: [ListRowView.Configuration]()) { partialResult, configuration in
            partialResult.append(.init(
                configuration.interaction,
                headerText: nil,
                innerText: configuration.innerText,
                footerText: nil,
                innerTextColor: configuration.innerTextColor,
                isEnabled: configuration.isEnabled,
                isInspectable: configuration.isInspectable,
                cornerRadius: 0,
                imageView: configuration.imageView
            ))
        }
    }
}

private extension String {
    var trimmingTrailingNewlines: String {
        var string = self
        while string.hasSuffix("\n") {
            string = string.dropSuffix()
        }
        return string
    }
}
