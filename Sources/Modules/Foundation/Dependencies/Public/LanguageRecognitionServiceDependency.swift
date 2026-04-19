//
//  LanguageRecognitionServiceDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/* Proprietary */
import Translator

/// The dependency key that provides a ``LanguageRecognitionService`` instance.
public enum LanguageRecognitionServiceDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> LanguageRecognitionService {
        .shared
    }
}

public extension DependencyValues {
    /// The shared ``LanguageRecognitionService`` instance.
    var languageRecognitionService: LanguageRecognitionService {
        get { self[LanguageRecognitionServiceDependency.self] }
        set { self[LanguageRecognitionServiceDependency.self] = newValue }
    }
}
