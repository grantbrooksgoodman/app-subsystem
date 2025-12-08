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
    func navigationBarItemGlassTint(
        _ color: Color,
        for placement: NavigationBar.ItemPlacement
    ) -> some View {
        navigationBarItemGlassTint(
            color,
            for: [placement]
        )
    }

    func navigationBarItemGlassTint(
        _ color: Color,
        for placement: NavigationBar.ItemPlacement...
    ) -> some View {
        navigationBarItemGlassTint(
            color,
            for: Set(placement)
        )
    }

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
