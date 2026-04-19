//
//  NavigationBarItemGlassTintViewModifier.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

private struct NavigationBarItemGlassTintViewModifier: ViewModifier {
    // MARK: - Properties

    private let color: Color
    private let placement: Set<NavigationBar.ItemPlacement>

    // MARK: - Init

    init(
        _ color: Color,
        for placement: Set<NavigationBar.ItemPlacement>
    ) {
        self.color = color
        self.placement = placement
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .if(UIApplication.isGlassTintingEnabled) {
                $0.onNavigationTransition(.didAppear) { _ in
                    let color = UIColor(color)
                    placement.forEach {
                        NavigationBar.setItemGlassTint(
                            color,
                            for: $0
                        )
                    }
                }
            }
    }
}

public extension View {
    /// Tints navigation bar items at the given placement with a glass
    /// material color when glass tinting is enabled.
    ///
    /// - Parameters:
    ///   - color: The tint color to apply.
    ///   - placement: The bar item placement to tint.
    ///
    /// - Note: This modifier has no effect when glass tinting is not enabled.
    func navigationBarItemGlassTint(
        _ color: Color,
        for placement: NavigationBar.ItemPlacement
    ) -> some View {
        navigationBarItemGlassTint(
            color,
            for: [placement]
        )
    }

    /// Tints navigation bar items at the given placements with a
    /// glass material color when glass tinting is enabled.
    ///
    /// - Parameters:
    ///   - color: The tint color to apply.
    ///   - placement: The bar item placements to tint.
    ///
    /// - Note: This modifier has no effect when glass tinting is not enabled.
    func navigationBarItemGlassTint(
        _ color: Color,
        for placement: NavigationBar.ItemPlacement...
    ) -> some View {
        navigationBarItemGlassTint(
            color,
            for: Set(placement)
        )
    }

    /// Tints navigation bar items at the given placements with a
    /// glass material color when glass tinting is enabled.
    ///
    /// The tint is applied after the navigation transition completes.
    ///
    /// - Parameters:
    ///   - color: The tint color to apply.
    ///   - placement: The set of bar item placements to tint.
    ///
    /// - Note: This modifier has no effect when glass tinting is not enabled.
    func navigationBarItemGlassTint(
        _ color: Color,
        for placement: Set<NavigationBar.ItemPlacement>
    ) -> some View {
        modifier(
            NavigationBarItemGlassTintViewModifier(
                color,
                for: placement
            )
        )
    }
}
