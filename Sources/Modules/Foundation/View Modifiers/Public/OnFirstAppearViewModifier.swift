//
//  OnFirstAppearViewModifier.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

private struct OnFirstAppearViewModifier: ViewModifier {
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
        content.onAppear {
            guard !didAppear else { return }
            didAppear = true
            action()
        }
    }
}

public extension View {
    /// Performs an action only the first time the view appears.
    ///
    /// Subsequent appearances of the same view instance do not
    /// trigger the action.
    ///
    /// - Parameter action: The closure to execute on first appear.
    func onFirstAppear(_ action: @escaping (() -> Void)) -> some View {
        modifier(OnFirstAppearViewModifier(action))
    }
}
