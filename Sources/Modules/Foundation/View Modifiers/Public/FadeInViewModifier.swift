//
//  FadeInViewModifier.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

private struct FadeInViewModifier: ViewModifier {
    // MARK: - Properties

    private let delay: Duration
    private let duration: Duration

    @State private var opacity: CGFloat = 0

    // MARK: - Init

    init(_ duration: Duration, delay: Duration) {
        self.duration = duration
        self.delay = delay
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                func animateOpacity() { withAnimation(.easeIn(duration: duration.timeInterval)) { opacity = 1 } }
                guard delay != .zero else { return animateOpacity() }
                Task.delayed(by: delay) { @MainActor in
                    animateOpacity()
                }
            }
    }
}

public extension View {
    func fadeIn(_ duration: Duration = .milliseconds(500), delay: Duration = .zero) -> some View {
        modifier(FadeInViewModifier(duration, delay: delay))
    }
}
