//
//  BuildInfoOverlay.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public enum BuildInfoOverlay {
    // MARK: - Properties

    public static var isHidden: Bool {
        Observables.isBuildInfoOverlayHidden.value
    }

    // MARK: - Methods

    public static func hide(persistSetting: Bool = true) {
        Observables.isBuildInfoOverlayHidden.value = true
        guard persistSetting else { return }
        @Persistent(.hidesBuildInfoOverlay) var hidesBuildInfoOverlay: Bool?
        hidesBuildInfoOverlay = true
    }

    public static func show(persistSetting: Bool = true) {
        Observables.isBuildInfoOverlayHidden.value = false
        guard persistSetting else { return }
        @Persistent(.hidesBuildInfoOverlay) var hidesBuildInfoOverlay: Bool?
        hidesBuildInfoOverlay = false
    }
}
