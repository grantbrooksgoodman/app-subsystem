//
//  InteractivePopGestureRecognizerDisabledViewModifier.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI
import UIKit

/// A service for enabling or disabling the interactive pop gesture
/// recognizer used by navigation controllers.
@MainActor
public enum InteractivePopGestureRecognizer {
    // MARK: - Properties

    /// A Boolean value indicating whether the interactive pop gesture
    /// recognizer is currently enabled.
    public private(set) static var isEnabled = true

    // MARK: - Set Is Enabled

    /// Enables or disables the interactive pop gesture recognizer.
    ///
    /// This method has no effect when the app is not in the
    /// active state.
    ///
    /// - Parameter isEnabled: Pass `true` to enable the gesture, or
    ///   `false` to disable it.
    public static func setIsEnabled(_ isEnabled: Bool) {
        @Dependency(\.uiApplication.applicationState) var applicationState: UIApplication.State
        guard applicationState == .active else { return }
        self.isEnabled = isEnabled
    }
}

// swiftlint:disable:next type_name
private struct InteractivePopGestureRecognizerDisabledViewModifier: ViewModifier {
    // MARK: - Properties

    private let isDisabled: Bool

    @State private var initialValue = InteractivePopGestureRecognizer.isEnabled

    // MARK: - Init

    init(_ isDisabled: Bool) {
        self.isDisabled = isDisabled
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .onAppear { InteractivePopGestureRecognizer.setIsEnabled(!isDisabled) }
            .onChange(of: isDisabled) { _, newValue in
                InteractivePopGestureRecognizer.setIsEnabled(!newValue)
            }
            .onDisappear { InteractivePopGestureRecognizer.setIsEnabled(initialValue) }
    }
}

public extension View {
    /// Disables the interactive pop gesture recognizer while the view
    /// is visible, restoring the previous state on disappear.
    ///
    /// - Parameter isDisabled: Pass `true` to disable the gesture.
    ///   The default is `true`.
    func interactivePopGestureRecognizerDisabled(_ isDisabled: Bool = true) -> some View {
        modifier(InteractivePopGestureRecognizerDisabledViewModifier(isDisabled))
    }
}
