//
//  RootSheet.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

public struct RootSheet {
    // MARK: - Properties

    public let view: AnyView

    // MARK: - Init

    public init(_ view: AnyView) {
        self.view = view
    }
}
