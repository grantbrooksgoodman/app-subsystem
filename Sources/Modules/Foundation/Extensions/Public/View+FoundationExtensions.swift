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

    func onTraitCollectionChange(perform action: @escaping () -> Void) -> some View {
        onReceive(.traitCollectionChangedNotification) { _ in
            action()
        }
    }
}
