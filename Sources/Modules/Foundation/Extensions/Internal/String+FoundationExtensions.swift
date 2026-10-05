//
//  String+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

extension StringProtocol {
    func distance(of element: Element) -> Int? {
        firstIndex(of: element)?.distance(in: self)
    }

    func distance(of string: some StringProtocol) -> Int? {
        range(of: string)?.lowerBound.distance(in: self)
    }
}

extension String.Index {
    func distance(in string: some StringProtocol) -> Int {
        string.distance(to: self)
    }
}
