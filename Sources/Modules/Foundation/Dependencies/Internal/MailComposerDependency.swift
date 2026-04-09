//
//  MailComposerDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

enum MailComposerDependency: DependencyKey {
    static func resolve(_: DependencyValues) -> MailComposer {
        @MainActorIsolated var mailComposer = MailComposer.shared
        return mailComposer
    }
}

extension DependencyValues {
    var mailComposer: MailComposer {
        get { self[MailComposerDependency.self] }
        set { self[MailComposerDependency.self] = newValue }
    }
}
