//
//  LocalizedStringKeyRepresentable.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public protocol LocalizedStringKeyRepresentable: RawRepresentable, Equatable {
    var referent: String { get }
}
