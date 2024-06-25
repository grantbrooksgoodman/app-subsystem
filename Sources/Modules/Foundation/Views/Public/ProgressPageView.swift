//
//  ProgressPageView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

public struct ProgressPageView: View {
    // MARK: - Constants Accessors

    private typealias Floats = FoundationConstants.CGFloats.ProgressPageView

    // MARK: - Properties

    private let backgroundColor: Color

    // MARK: - Init

    public init(backgroundColor: Color = Color.background) {
        self.backgroundColor = backgroundColor
    }

    // MARK: - View

    public var body: some View {
        ThemedView {
            ProgressView()
                .dynamicTypeSize(.large)
                .fadeIn(
                    .milliseconds(Floats.fadeInDurationMilliseconds),
                    delay: .milliseconds(Floats.fadeInDelayMilliseconds)
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
        .interactivePopGestureRecognizerDisabled()
    }
}
