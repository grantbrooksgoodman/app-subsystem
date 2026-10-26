//
//  Exception+InternalFoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

extension Exception {
    var hydrated: Exception {
        appending(userInfo: [
            UserInfo.descriptor.rawValue: descriptor,
            UserInfo.errorCode.rawValue: code,
        ])
    }
}
