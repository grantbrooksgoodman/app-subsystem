//
//  NavigationBarAppearanceViewModifier.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

private struct NavigationBarAppearanceViewModifier: ViewModifier {
    // MARK: - Properties

    private let appearance: NavigationBarAppearance
    private let previousAppearance: NavigationBarAppearance?
    private let restoreOnDisappear: Bool

    @State private var viewID = UUID()

    // MARK: - Init

    init(
        _ appearance: NavigationBarAppearance,
        restoreOnDisappear: Bool
    ) {
        self.appearance = appearance
        self.restoreOnDisappear = restoreOnDisappear
        previousAppearance = NavigationBar.currentAppearance
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .id(viewID)
            .onAppear {
                NavigationBar.setAppearance(appearance)
            }
            .onTraitCollectionChange {
                NavigationBar.setAppearance(appearance)
                viewID = UUID()
            }
            .if(restoreOnDisappear) {
                $0.onDisappear {
                    guard let previousAppearance else { return }
                    NavigationBar.setAppearance(previousAppearance)
                }
            }
    }
}

public extension View {
    /// Applies a navigation bar appearance while the view is visible,
    /// automatically reapplying it when the trait collection changes.
    ///
    /// - Parameters:
    ///   - appearance: The navigation bar appearance to apply.
    ///   - restoreOnDisappear: Whether to restore the previous
    ///     appearance when the view disappears. The default is `true`.
    func navigationBarAppearance(
        _ appearance: NavigationBarAppearance,
        restoreOnDisappear: Bool = true
    ) -> some View {
        modifier(
            NavigationBarAppearanceViewModifier(
                appearance,
                restoreOnDisappear: restoreOnDisappear
            )
        )
    }
}
