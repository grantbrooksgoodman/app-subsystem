//
//  TranslatorConfigDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import Translator

public enum TranslatorConfigDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> Translator.Config {
        .shared
    }
}

public extension DependencyValues {
    var translatorConfig: Translator.Config {
        get { self[TranslatorConfigDependency.self] }
        set { self[TranslatorConfigDependency.self] = newValue }
    }
}
