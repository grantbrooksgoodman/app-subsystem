//
//  TouchProxy.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/* Proprietary */
import Foundation

struct TouchProxy: UIViewRepresentable {
    // MARK: - Make UIView

    func makeUIView(context: Context) -> UIControl {
        let control = UIControl()
        control.backgroundColor = .clear
        return control
    }

    // MARK: - Update UIView

    func updateUIView(_ uiView: UIControl, context: Context) {}
}
