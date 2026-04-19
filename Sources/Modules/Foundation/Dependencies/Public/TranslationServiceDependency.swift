//
//  TranslationServiceDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/* Proprietary */
import Translator

/// The dependency key that provides a ``TranslationService`` instance.
public enum TranslationServiceDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> TranslationService {
        .shared
    }
}

public extension DependencyValues {
    /// The shared ``TranslationService`` instance.
    var translationService: TranslationService {
        get { self[TranslationServiceDependency.self] }
        set { self[TranslationServiceDependency.self] = newValue }
    }
}
