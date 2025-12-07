//
//  PopGestureViewModifier.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

private struct PopGestureViewModifier: ViewModifier {
    // MARK: - Constants Accessors

    private typealias Floats = FoundationConstants.CGFloats.PopGestureViewModifier

    // MARK: - Properties

    private let action: () -> Void

    @State private var didAppear = false

    // MARK: - Init

    init(_ action: @escaping () -> Void) {
        self.action = action
        didAppear = false
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .gesture(
                DragGesture(
                    minimumDistance: Floats.dragGestureMinimumDistance,
                    coordinateSpace: .global
                )
                .onChanged { value in
                    guard value.startLocation.x < Floats.dragGestureValueLeftEdgeThreshold,
                          value.translation.width > Floats.dragGestureValueRightSwipeThreshold else { return }
                    action()
                }
            )
    }
}

extension View {
    func popGesture(_ action: @escaping (() -> Void)) -> some View {
        modifier(PopGestureViewModifier(action))
    }
}
