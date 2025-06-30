//
//  ForcedUpdateModalDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Combine
import Foundation

public extension AppSubsystem.Delegates {
    protocol ForcedUpdateModalDelegate {
        var installButtonRedirectURL: URL? { get }
        var isForcedUpdateRequiredSubject: CurrentValueSubject<Bool?, Never> { get }
    }
}

public extension AppSubsystem.Delegates.ForcedUpdateModalDelegate {
    var forcedUpdateRequiredPublisher: AnyPublisher<Bool, Never> {
        isForcedUpdateRequiredSubject
            .compactMap { $0 }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
