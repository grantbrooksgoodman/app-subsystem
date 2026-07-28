//
//  BuildInfoOverlay.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

enum BuildInfoOverlay {
    // MARK: - Properties

    static var isHidden: Bool {
        Shared.isBuildInfoOverlayHidden.value
    }

    // MARK: - Methods

    static func hide(persistSetting: Bool = true) {
        Shared.isBuildInfoOverlayHidden.value = true
        guard persistSetting else { return }
        @Persistent(.hidesBuildInfoOverlay) var hidesBuildInfoOverlay: Bool?
        hidesBuildInfoOverlay = true
    }

    static func show(persistSetting: Bool = true) {
        Shared.isBuildInfoOverlayHidden.value = false
        guard persistSetting else { return }
        @Persistent(.hidesBuildInfoOverlay) var hidesBuildInfoOverlay: Bool?
        hidesBuildInfoOverlay = false
    }
}
