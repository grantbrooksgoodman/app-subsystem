//
//  ForcedUpdateModalPageReducer.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/* Proprietary */
import Translator

struct ForcedUpdateModalPageReducer: Reducer {
    // MARK: - Dependencies

    @Dependency(\.build) private var build: Build
    @Dependency(\.coreKit) private var core: CoreKit
    @Dependency(\.translationService) private var translator: TranslationService
    @Dependency(\.uiApplication) private var uiApplication: UIApplication

    // MARK: - Actions

    enum Action {
        case viewAppeared

        case installButtonTapped
        case remoteAppIconImageReturned(UIImage?)
        case resolveReturned(Callback<[TranslationOutputMap], Exception>)
    }

    // MARK: - State

    struct State: Equatable {
        /* MARK: Properties */

        var appIconImage: Image?
        var shouldShowInstallButton = false
        var strings: [TranslationOutputMap] = ForcedUpdateModalPageViewStrings.defaultOutputMap
        var versionLabelText = ""
        var viewState: StatefulView.ViewState = .loading

        fileprivate var installButtonRedirectURL: URL? { AppSubsystem.delegates.forcedUpdateModal?.installButtonRedirectURL }

        /* MARK: Init */

        init() {}
    }

    // MARK: - Init

    init() {}

    // MARK: - Reduce

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .viewAppeared:
            state.appIconImage = AppIconImageUtility.shared.localAppIconImage.swiftUIImage
            if let installButtonRedirectURL = state.installButtonRedirectURL,
               uiApplication.canOpenURL(installButtonRedirectURL) {
                state.shouldShowInstallButton = true
            }

            state.versionLabelText = "v\(build.bundleVersion) (\(String(build.buildNumber))\(build.milestone.shortString)/\(build.bundleRevision.lowercased()))"

            func hideInteractiveContent() {
                Toast.hide()

                uiApplication
                    .windows?
                    .first(where: { $0.tag == core.ui.semTag(for: "ROOT_OVERLAY_WINDOW") })?
                    .alpha = 0

                uiApplication.dismissAlertControllers(animated: false)
                uiApplication.dismissSheets(animated: false)
                uiApplication.resignFirstResponders()

                guard !build.isDeveloperModeEnabled else { return }
                core.gcd.after(.milliseconds(100)) { hideInteractiveContent() }
            }; hideInteractiveContent()

            let remoteAppIconImageTask: Effect<Action> = .task {
                let result = await AppIconImageUtility.shared.remoteAppIconImage
                return .remoteAppIconImageReturned(result)
            }

            let resolveTask: Effect<Action> = .task {
                let result = await translator.resolve(ForcedUpdateModalPageViewStrings.self)
                return .resolveReturned(result)
            }

            return remoteAppIconImageTask.merge(with: resolveTask)

        case .installButtonTapped:
            guard let installButtonRedirectURL = state.installButtonRedirectURL else { return .none }
            Task { @MainActor in
                uiApplication.open(installButtonRedirectURL)
            }

        case let .remoteAppIconImageReturned(remoteAppIconImage):
            guard let remoteAppIconImage else { return .none }
            state.appIconImage = .init(uiImage: remoteAppIconImage)

        case let .resolveReturned(.success(strings)):
            state.strings = strings
            state.viewState = .loaded

        case let .resolveReturned(.failure(exception)):
            Logger.log(exception)
            state.viewState = .loaded
        }

        return .none
    }
}
