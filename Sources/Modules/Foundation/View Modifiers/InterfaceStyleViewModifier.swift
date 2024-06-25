//
//  InterfaceStyleViewModifier.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

private struct InterfaceStyleViewModifier: ViewModifier {
    // MARK: - Dependencies

    @Dependency(\.coreKit) private var core: CoreKit
    @Dependency(\.uiApplication) private var uiApplication: UIApplication

    // MARK: - Properties

    private let interfaceStyle: UIUserInterfaceStyle

    // MARK: - Init

    public init(_ interfaceStyle: UIUserInterfaceStyle) {
        self.interfaceStyle = interfaceStyle
    }

    // MARK: - Body

    public func body(content: Content) -> some View {
        content
            .preferredColorScheme(.init(interfaceStyle))
            .onAppear { overrideStyle() }
            .onDisappear { core.ui.overrideUserInterfaceStyle(ThemeService.currentTheme.style) }
    }

    // MARK: - Auxiliary Methods

    private func overrideStyle() {
        guard uiApplication.applicationState == .active else {
            return core.gcd.after(.milliseconds(10)) { overrideStyle() }
        }

        guard uiApplication.interfaceStyle != interfaceStyle else { return }
        core.ui.overrideUserInterfaceStyle(interfaceStyle)
    }
}

public extension View {
    func interfaceStyle(_ interfaceStyle: UIUserInterfaceStyle) -> some View {
        modifier(InterfaceStyleViewModifier(interfaceStyle))
    }
}
