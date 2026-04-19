//
//  TranslatorConfigDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/* Proprietary */
import Translator

/// The dependency key that provides a ``Translator/Config`` instance.
public enum TranslatorConfigDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> Translator.Config {
        Translator.config
    }
}

public extension DependencyValues {
    /// The shared ``Translator/Config`` instance.
    var translatorConfig: Translator.Config {
        get { self[TranslatorConfigDependency.self] }
        set { self[TranslatorConfigDependency.self] = newValue }
    }
}
