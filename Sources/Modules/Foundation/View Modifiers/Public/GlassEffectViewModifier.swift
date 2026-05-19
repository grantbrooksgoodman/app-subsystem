//
//  GlassEffectViewModifier.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

public extension View {
    func glassEffect(
        isClear: Bool = false,
        padding edgePadding: CGFloat? = nil,
        shape: some Shape = .capsule,
        tint: Color? = nil
    ) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26, *) {
            if let edgePadding {
                padding(.all, edgePadding)
                    .glassEffect(
                        (isClear ? Glass.clear : .regular)
                            .tint(tint),
                        in: shape
                    )
                    .eraseToAnyView()
            } else {
                glassEffect(
                    (isClear ? Glass.clear : .regular)
                        .tint(tint),
                    in: shape
                )
                .eraseToAnyView()
            }
        } else {
            eraseToAnyView()
        }
        #else
        eraseToAnyView()
        #endif
    }
}
