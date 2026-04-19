//
//  AKInspectionDelegate.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

/* Proprietary */
import AlertKit

@MainActor
struct InspectionDelegate: AlertKit.InspectionDelegate {
    // MARK: - Init

    private init() {}

    // MARK: - Register with Dependencies

    static func registerWithDependencies() {
        @Dependency(\.alertKitConfig) var alertKitConfig: AlertKit.Config
        alertKitConfig.registerInspectionDelegate(InspectionDelegate())
    }

    // MARK: - AlertKit.InspectionDelegate Conformance

    func sourceItem(_ tag: Int) -> UIView? {
        @Dependency(\.uiApplication) var uiApplication: UIApplication
        return uiApplication.presentedViews
            .compactMap { $0 as? UILabel }
            .first(where: { $0.tag == tag })
    }
}
