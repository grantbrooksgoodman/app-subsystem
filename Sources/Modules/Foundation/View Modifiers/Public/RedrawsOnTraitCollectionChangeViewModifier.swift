//
//  RedrawsOnTraitCollectionChangeViewModifier.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

// swiftlint:disable:next type_name
private struct RedrawsOnTraitCollectionChangeViewModifier: ViewModifier {
    // MARK: - Properties

    @State private var viewID = UUID()

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .id(viewID)
            .onTraitCollectionChange { viewID = UUID() }
    }
}

public extension View {
    /// Forces the view to update whenever the trait collection
    /// changes – for example, when switching between light and dark
    /// mode.
    func redrawsOnTraitCollectionChange() -> some View {
        modifier(RedrawsOnTraitCollectionChangeViewModifier())
    }
}
