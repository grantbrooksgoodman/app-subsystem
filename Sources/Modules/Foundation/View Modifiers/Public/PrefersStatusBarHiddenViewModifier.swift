//
//  PrefersStatusBarHiddenViewModifier.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

private struct PrefersStatusBarHiddenViewModifier: ViewModifier {
    // MARK: - Properties

    private let isHidden: Bool
    private let restoreOnDisappear: Bool

    // MARK: - Init

    init(
        _ isHidden: Bool,
        restoreOnDisappear: Bool
    ) {
        self.isHidden = isHidden
        self.restoreOnDisappear = restoreOnDisappear
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .onAppear {
                StatusBar.setIsHidden(isHidden)
            }
            .if(restoreOnDisappear) {
                $0.onDisappear {
                    StatusBar.setIsHidden(!isHidden)
                }
            }
    }
}

public extension View {
    /// Hides or shows the status bar while the view is visible.
    ///
    /// - Parameters:
    ///   - isHidden: Pass `true` to hide the status bar. The
    ///     default is `true`.
    ///   - restoreOnDisappear: Whether to restore the previous
    ///     visibility when the view disappears. The default is
    ///     `true`.
    func prefersStatusBarHidden(
        _ isHidden: Bool = true,
        restoreOnDisappear: Bool = true
    ) -> some View {
        modifier(
            PrefersStatusBarHiddenViewModifier(
                isHidden,
                restoreOnDisappear: restoreOnDisappear
            )
        )
    }
}
