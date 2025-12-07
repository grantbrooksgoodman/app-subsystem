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

    init(
        style: UIStatusBarStyle,
        restoreOnDisappear: Bool
    ) {
        preferredStatusBarStyle = style
        self.restoreOnDisappear = restoreOnDisappear
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        if restoreOnDisappear {
            content
                .onAppear { StatusBar.overrideStyle(preferredStatusBarStyle) }
                .onDisappear { StatusBar.restoreStyle() }
        } else {
            content
                .onAppear { StatusBar.overrideStyle(preferredStatusBarStyle) }
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
