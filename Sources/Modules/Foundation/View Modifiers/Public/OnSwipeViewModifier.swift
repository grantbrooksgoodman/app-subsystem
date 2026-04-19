//
//  OnSwipeViewModifier.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/// Constants that control swipe gesture detection thresholds.
public enum SwipeModifierConfig {
    /// The multiplier applied to the sensitivity value when
    /// evaluating predicted end translation.
    public static let sensitivityFactor: CGFloat = 400

    /// The minimum drag distance required to recognize a swipe
    /// gesture.
    public static let minimumDragGestureDistance: CGFloat = 30
}

/// An option set representing one or more swipe directions.
///
/// Combine directions to recognize multiple swipe gestures with a
/// single modifier:
///
/// ```swift
/// myView.onSwipe([.left, .right]) {
///     print("Swiped horizontally")
/// }
/// ```
public struct Swipe: OptionSet, Equatable {
    // MARK: - Properties

    /// The raw integer value of the swipe direction.
    public let rawValue: Int

    fileprivate var swiped: ((DragGesture.Value, CGFloat) -> Bool) = { _, _ in false }

    // MARK: - Computed Properties

    /// All four swipe directions.
    public static var all: Swipe { [.down, .left, .right, .up] }

    /// A downward swipe.
    public static var down: Swipe {
        var swipe = Swipe(rawValue: 1 << 3)
        swipe.swiped = { value, sensitivity in
            value.translation.height > 0 && value.predictedEndTranslation.height > sensitivity * SwipeModifierConfig.sensitivityFactor
        }
        return swipe
    }

    /// A leftward swipe.
    public static var left: Swipe {
        var swipe = Swipe(rawValue: 1 << 0)
        swipe.swiped = { value, sensitivity in
            value.translation.width < 0 && value.predictedEndTranslation.width < sensitivity * SwipeModifierConfig.sensitivityFactor
        }
        return swipe
    }

    /// A rightward swipe.
    public static var right: Swipe {
        var swipe = Swipe(rawValue: 1 << 1)
        swipe.swiped = { value, sensitivity in
            value.translation.width > 0 && value.predictedEndTranslation.width > sensitivity * SwipeModifierConfig.sensitivityFactor
        }
        return swipe
    }

    /// An upward swipe.
    public static var up: Swipe {
        var swipe = Swipe(rawValue: 1 << 2)
        swipe.swiped = { value, sensitivity in
            value.translation.height < 0 && value.predictedEndTranslation.height < sensitivity * SwipeModifierConfig.sensitivityFactor
        }
        return swipe
    }

    fileprivate var array: [Swipe] { [.left, .right, .up, .down].filter { contains($0) } }

    // MARK: - Init

    /// Creates a swipe direction with the given raw value.
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public extension View {
    /// Performs an action when the user swipes in one or more
    /// directions.
    ///
    /// - Parameters:
    ///   - swipe: The swipe direction or directions to recognize.
    ///   - sensitivity: A multiplier that adjusts the predicted
    ///     translation threshold. The default is `1`.
    ///   - action: The closure to execute when a matching swipe is
    ///     detected.
    func onSwipe(
        _ swipe: Swipe,
        sensitivity: CGFloat = 1,
        action: @escaping () -> Void
    ) -> some View {
        gesture(
            DragGesture(
                minimumDistance: SwipeModifierConfig.minimumDragGestureDistance,
                coordinateSpace: .local
            )
            .onEnded { value in
                for swipe in swipe.array where swipe.swiped(value, sensitivity) {
                    action()
                }
            }
        )
    }
}
