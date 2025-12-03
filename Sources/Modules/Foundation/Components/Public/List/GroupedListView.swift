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

public struct GroupedListView: View {
    // MARK: - Constants Accessors

    private typealias Floats = FoundationConstants.CGFloats.GroupedListView

    // MARK: - Properties

    private let footerText: String?
    private let headerText: String?
    private let rows: [ListRowView.Configuration]

    // MARK: - Init

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

private extension Array where Element == ListRowView.Configuration {
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
