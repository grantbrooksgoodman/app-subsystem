//
//  StatusBarStyleViewModifier.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

private struct StatusBarStyleViewModifier: ViewModifier {
    // MARK: - Properties

    private let preferredStatusBarStyle: UIStatusBarStyle
    private let restoreOnDisappear: Bool

    // MARK: - Init

    public init(
        style: UIStatusBarStyle,
        restoreOnDisappear: Bool
    ) {
        preferredStatusBarStyle = style
        self.restoreOnDisappear = restoreOnDisappear
    }

    // MARK: - Body

    public func body(content: Content) -> some View {
        if restoreOnDisappear {
            content
                .onAppear { StatusBarStyle.override(preferredStatusBarStyle) }
                .onDisappear { StatusBarStyle.restore() }
        } else {
            content
                .onAppear { StatusBarStyle.override(preferredStatusBarStyle) }
        }
    }
}

public extension View {
    func preferredStatusBarStyle(
        _ style: UIStatusBarStyle,
        restoreOnDisappear: Bool = true
    ) -> some View {
        modifier(StatusBarStyleViewModifier(style: style, restoreOnDisappear: restoreOnDisappear))
    }
}
