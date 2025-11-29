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

struct InspectionDelegate: AlertKit.InspectionDelegate {
    // MARK: - Dependencies

    @Dependency(\.alertKitConfig) private var alertKitConfig: AlertKit.Config
    @Dependency(\.uiApplication.presentedViews) private var presentedViews: [UIView]

    // MARK: - Init

    fileprivate init() {}

    // MARK: - Register with Dependencies

    static func registerWithDependencies() {
        @Dependency(\.alertKitConfig) var alertKitConfig: AlertKit.Config
        alertKitConfig.registerInspectionDelegate(InspectionDelegate())
    }

    // MARK: - AlertKit.InspectionDelegate Conformance

    func sourceItem(_ tag: Int) -> UIView? {
        presentedViews
            .compactMap { $0 as? UILabel }
            .first(where: { $0.tag == tag })
    }
}
