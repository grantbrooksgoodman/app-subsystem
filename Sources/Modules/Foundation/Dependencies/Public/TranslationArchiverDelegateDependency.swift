//
//  TranslationArchiverDelegateDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/* Proprietary */
import Translator

/// The dependency key that provides a ``TranslationArchiverDelegate``
/// instance.
public enum TranslationArchiverDelegateDependency: DependencyKey {
    public static func resolve(_ dependencies: DependencyValues) -> TranslationArchiverDelegate {
        dependencies.translatorConfig.archiverDelegate ?? LocalTranslationArchiverDelegate()
    }
}

public extension DependencyValues {
    /// The shared ``TranslationArchiverDelegate`` instance.
    var translationArchiverDelegate: TranslationArchiverDelegate {
        get { self[TranslationArchiverDelegateDependency.self] }
        set { self[TranslationArchiverDelegateDependency.self] = newValue }
    }
}
