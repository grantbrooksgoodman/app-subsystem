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

public enum LanguageRecognitionServiceDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> LanguageRecognitionService {
        .shared
    }
}

public extension DependencyValues {
    var languageRecognitionService: LanguageRecognitionService {
        get { self[LanguageRecognitionServiceDependency.self] }
        set { self[LanguageRecognitionServiceDependency.self] = newValue }
    }
}
