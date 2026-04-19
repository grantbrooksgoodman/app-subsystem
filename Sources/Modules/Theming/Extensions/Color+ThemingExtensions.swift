//
//  Color+ThemingExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/// Convenience accessors for themed colors in SwiftUI.
///
/// These properties resolve against the active theme's palette and
/// automatically reflect theme and appearance changes when used inside a
/// ``ThemedView``:
///
/// ```swift
/// Text("Hello")
///     .foregroundStyle(.titleText)
///     .background(.background)
/// ```
///
@MainActor
public extension Color {
    static var accent: Color { .init(uiColor: .accent) }
    static var background: Color { .init(uiColor: .background) }
    static var disabled: Color { .init(uiColor: .disabled) }
    static var groupedContentBackground: Color { .init(uiColor: .groupedContentBackground) }

    static var navigationBarBackground: Color { .init(uiColor: .navigationBarBackground) }
    static var navigationBarTitle: Color { .init(uiColor: .navigationBarTitle) }

    static var subtitleText: Color { .init(uiColor: .subtitleText) }
    static var titleText: Color { .init(uiColor: .titleText) }
}
