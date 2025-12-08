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
    private let restoreOnDisappear: Bool

    // MARK: - Init

    init(
        _ interfaceStyle: UIUserInterfaceStyle,
        restoreOnDisappear: Bool
    ) {
        self.interfaceStyle = interfaceStyle
        self.restoreOnDisappear = restoreOnDisappear
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(.init(interfaceStyle))
            .onAppear { overrideStyle() }
            .if(restoreOnDisappear) {
                $0.onDisappear {
                    core.ui.overrideUserInterfaceStyle(ThemeService.currentTheme.style)
                }
            }
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
    func interfaceStyle(
        _ interfaceStyle: UIUserInterfaceStyle,
        restoreOnDisappear: Bool = true
    ) -> some View {
        modifier(InterfaceStyleViewModifier(
            interfaceStyle,
            restoreOnDisappear: restoreOnDisappear
        ))
    }
}
