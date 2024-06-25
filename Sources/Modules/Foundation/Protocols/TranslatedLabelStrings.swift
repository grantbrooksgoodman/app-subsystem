//
//  TranslatedLabelStrings.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public protocol TranslatedLabelStrings {
    static var keyPairs: [TranslationInputMap] { get }
}

public protocol TranslatedLabelStringKey {
    var alternate: String? { get }
}

public extension TranslatedLabelStrings {
    static var defaultOutputMap: [TranslationOutputMap] {
        keyPairs.map(\.defaultOutputMap)
    }
}
