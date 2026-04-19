//
//  View+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

public extension View {
    /// Wraps the view in an `AnyView` for type erasure.
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }

    /// Conditionally applies a transform to the view.
    @ViewBuilder
    func `if`(
        _ condition: Bool,
        _ transform: (Self) -> some View
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Conditionally applies one of two transforms to the view.
    @ViewBuilder
    func `if`(
        _ condition: Bool,
        _ ifTransform: (Self) -> some View,
        else elseTransform: (Self) -> some View
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }

    /// Applies a transform when the optional value is non-`nil`,
    /// passing the unwrapped value to the closure.
    @ViewBuilder
    func ifLet<Wrapped>(
        _ optional: Wrapped?,
        _ transform: (Self, Wrapped) -> some View
    ) -> some View {
        if let value = optional {
            transform(self, value)
        } else {
            self
        }
    }

    /// Applies one of two transforms depending on whether the
    /// optional value is non-`nil`.
    @ViewBuilder
    func ifLet<Wrapped>(
        _ optional: Wrapped?,
        _ ifTransform: (Self, Wrapped) -> some View,
        else elseTransform: (Self) -> some View
    ) -> some View {
        if let value = optional {
            ifTransform(self, value)
        } else {
            elseTransform(self)
        }
    }

    /// Performs an action when a notification with the given name is
    /// posted.
    func onReceive(
        _ name: Notification.Name,
        center: NotificationCenter = .default,
        object: AnyObject? = nil,
        perform action: @escaping (Notification) -> Void
    ) -> some View {
        onReceive(
            center.publisher(for: name, object: object),
            perform: action
        )
    }

    /// Performs an action when the trait collection changes.
    func onTraitCollectionChange(perform action: @escaping () -> Void) -> some View {
        onReceive(.traitCollectionChangedNotification) { _ in
            action()
        }
    }
}
