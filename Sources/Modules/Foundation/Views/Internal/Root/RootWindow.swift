//
//  RootWindow.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

final class RootWindowStatus: ObservableObject {
    // MARK: - Types

    enum RootView {
        case appContent
        case expiryOverlay
    }

    // MARK: - Dependencies

    @Dependency(\.build) private var build: Build

    // MARK: - Properties

    static let shared = RootWindowStatus()

    var buildExpiryOverrideTriggered = false {
        didSet { rootView = buildExpiryOverrideTriggered ? .appContent : rootView }
    }

    @Published var rootView: RootView = .appContent

    // MARK: - Init

    private init() {
        if build.isTimebombActive,
           build.expiryDate.comparator <= Date.now.comparator {
            rootView = .expiryOverlay
        }
    }
}

struct RootWindow: View {
    // MARK: - Properties

    private let view: any View

    @ObservedObject private var status = RootWindowStatus.shared

    // MARK: - Init

    init(_ view: any View) {
        self.view = view
    }

    // MARK: - View

    var body: some View {
        switch status.rootView {
        case .appContent: AnyView(view)
        case .expiryOverlay: ExpiryOverlayView()
        }
    }
}
