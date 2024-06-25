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

    // MARK: - Init

    public init(style: UIStatusBarStyle) {
        preferredStatusBarStyle = style
    }

    // MARK: - Body

    public func body(content: Content) -> some View {
        content
            .onAppear { StatusBarStyle.override(preferredStatusBarStyle) }
            .onDisappear { StatusBarStyle.restore() }
    }
}

public extension View {
    func preferredStatusBarStyle(_ style: UIStatusBarStyle) -> some View {
        modifier(StatusBarStyleViewModifier(style: style))
    }
}
