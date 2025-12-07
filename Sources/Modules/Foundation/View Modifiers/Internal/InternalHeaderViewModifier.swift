//
//  InternalHeaderViewModifier.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

private struct HeaderViewModifier: ViewModifier {
    // MARK: - Constants Accessors

    private typealias Floats = FoundationConstants.CGFloats.HeaderView

    // MARK: - Properties

    private let attributes: HeaderView.Attributes
    private let centerItem: HeaderView.CenterItemType?
    private let leftItem: HeaderView.PeripheralButtonType?
    private let popGestureAction: (() -> Void)?
    private let rightItem: HeaderView.PeripheralButtonType?

    // MARK: - Init

    init(
        leftItem: HeaderView.PeripheralButtonType?,
        centerItem: HeaderView.CenterItemType?,
        rightItem: HeaderView.PeripheralButtonType?,
        attributes: HeaderView.Attributes,
        popGestureAction: (() -> Void)?
    ) {
        self.leftItem = leftItem
        self.centerItem = centerItem
        self.rightItem = rightItem
        self.attributes = attributes
        self.popGestureAction = popGestureAction
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        VStack {
            HeaderView(
                leftItem: leftItem,
                centerItem: centerItem,
                rightItem: rightItem,
                attributes: attributes
            )
            .if(attributes.appearance == .themed) { headerView in
                ThemedView { headerView }
            }
            .zIndex(1)

            Spacer(minLength: 0)
            content
            Spacer(minLength: 0)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .toolbar(.hidden, for: .navigationBar)
        .ifLet(popGestureAction) { body, popGestureAction in
            body.popGesture(
                popGestureAction
            )
        }
    }
}

extension View {
    /// - Parameter attributes: Choosing a themed `appearance` value overrides all color values to those of the system theme.
    func header(
        leftItem: HeaderView.PeripheralButtonType? = nil,
        _ centerItem: HeaderView.CenterItemType? = nil,
        rightItem: HeaderView.PeripheralButtonType? = nil,
        attributes: HeaderView.Attributes = .init(),
        popGestureAction: (() -> Void)? = nil
    ) -> some View {
        modifier(
            HeaderViewModifier(
                leftItem: leftItem,
                centerItem: centerItem,
                rightItem: rightItem,
                attributes: attributes,
                popGestureAction: popGestureAction
            )
        )
    }
}
