//
//  Color+ThemingExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

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
