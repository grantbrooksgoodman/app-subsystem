//
//  Toast+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

/* Proprietary */
import AlertKit
import Translator

@MainActor
public extension Toast {
    // MARK: - Types

    /// Identifies which text components of a toast should be
    /// translated before display.
    ///
    /// Pass one or more keys to ``show(_:translating:languagePair:onTap:)``
    /// to request translation at runtime of the toast's title,
    /// message, or both.
    enum TranslationOptionKey: CaseIterable {
        /// The toast's body text.
        case message

        /// The toast's title text. Ignored if the toast has no
        /// title.
        case title
    }

    // MARK: - Properties

    internal private(set) static var overrideColorPalette: Toast.ColorPalette?

    private static var isHidden = true
    private static var keyboardHeight: CGFloat = 0

    // MARK: - Computed Properties

    private static var isShowingToast: Bool {
        UIApplication.iOS27IsAvailable ?
            !isHidden :
            (
                Observables.rootViewToast.value != nil ||
                    Observables.rootViewToastAction.value != nil
            )
    }

    // MARK: - Show / Hide

    /// Presents a toast notification, optionally translating its
    /// text components before display.
    ///
    /// When `keys` is empty, the toast is shown immediately with
    /// its original strings. When one or more
    /// ``TranslationOptionKey`` values are provided, the
    /// corresponding text is translated using the configured
    /// `AlertKit` translation delegate before presentation. If
    /// translation fails, the original untranslated toast is shown
    /// as a fallback and the error is logged.
    ///
    /// Presentation is automatically deferred while user interaction
    /// is blocked or another toast is already visible.
    ///
    /// If a toast identical to the one currently on screen is
    /// requested, the call is silently ignored.
    ///
    /// - Parameters:
    ///   - toast: The toast to present.
    ///   - keys: The text components to translate. Pass an empty
    ///     array to skip translation. The default is `[]`.
    ///   - languagePair: The language pair for translation. The
    ///     default is ``LanguagePair/system``.
    ///   - onTap: An optional closure executed when the user taps
    ///     the toast.
    static func show(
        _ toast: Toast,
        translating keys: [TranslationOptionKey] = [],
        languagePair: LanguagePair = .system,
        onTap: (@Sendable () -> Void)? = nil
    ) {
        @Dependency(\.alertKitConfig) var alertKitConfig: AlertKit.Config
        guard let translationDelegate = alertKitConfig.translationDelegate,
              !keys.isEmpty else {
            return Toast._show(
                toast,
                onTap: onTap
            )
        }

        let inputs = keys.reduce(into: [TranslationInput]()) { partialResult, key in
            switch key {
            case .message: partialResult.append(.init(toast.message))
            case .title: if let title = toast.title { partialResult.append(.init(title)) }
            }
        }

        Task {
            do {
                let translations = try await translationDelegate.getTranslations(
                    inputs,
                    languagePair: languagePair,
                    hud: alertKitConfig.translationHUDConfig,
                    timeout: alertKitConfig.translationTimeoutConfig
                )

                Toast.show(
                    .init(
                        toast.type,
                        title: toast.title == nil ? nil : translations.firstOutput(matching: toast.title!),
                        message: translations.firstOutput(matching: toast.message),
                        perpetuation: toast.perpetuation
                    ),
                    onTap: onTap
                )
            } catch {
                Logger.log(.init(
                    error,
                    metadata: .init(sender: self)
                ))

                Toast.show(
                    toast,
                    onTap: onTap
                )
            }
        }
    }

    /// Dismisses the currently visible toast, if any.
    ///
    /// Calling this method clears the observable toast state and
    /// resets the overlay window. If the build-info overlay was
    /// previously visible, it is restored after the toast is
    /// dismissed.
    ///
    /// This method is safe to call when no toast is showing; it
    /// returns immediately.
    static func hide() {
        guard UIApplication.iOS27IsAvailable else {
            Observables.rootViewToast.value = nil
            Observables.rootViewToastAction.value = nil
            return
        }

        @Dependency(\.uiApplication.mainWindow) var mainWindow: UIWindow?

        guard !isHidden,
              let rootOverlayWindow = mainWindow?.firstSubview(for: "ROOT_OVERLAY_WINDOW") else { return }

        Observables.rootViewToast.value = nil
        Observables.rootViewToastAction.value = nil

        @Persistent(.hidesBuildInfoOverlay) var hidesBuildInfoOverlay: Bool?
        if hidesBuildInfoOverlay == false {
            BuildInfoOverlay.show()
        }

        rootOverlayWindow.frame = BuildInfoOverlay.isHidden ? .zero : RootOverlayView.fallbackFrame
        rootOverlayWindow.isUserInteractionEnabled = !BuildInfoOverlay.isHidden

        isHidden = true
    }

    // MARK: - Override Default Color Palette

    /// Overrides the default toast color palette for all
    /// subsequently presented toasts.
    ///
    /// The override remains in effect until
    /// ``restoreDefaultColorPalette()`` is called.
    ///
    /// - Parameter colorPalette: The color palette to apply.
    static func overrideDefaultColorPalette(_ colorPalette: Toast.ColorPalette) {
        Toast.overrideColorPalette = colorPalette
    }

    /// Removes the current color palette override, restoring the
    /// default appearance for subsequently presented toasts.
    static func restoreDefaultColorPalette() {
        Toast.overrideColorPalette = nil
    }

    // MARK: - Auxiliary

    internal static func updateFrameForKeyboardAppearance(_ keyboardHeight: CGFloat) {
        @Dependency(\.uiApplication.mainWindow) var mainWindow: UIWindow?

        self.keyboardHeight = keyboardHeight
        guard !isHidden,
              let rootOverlayWindow = mainWindow?.firstSubview(for: "ROOT_OVERLAY_WINDOW"),
              let overlayFrame = frame(Observables.rootViewToast.value?.type.appearanceEdge ?? .top) else { return }

        rootOverlayWindow.frame = overlayFrame
        rootOverlayWindow.isUserInteractionEnabled = true
    }

    private static func frame(_ appearanceEdge: Toast.AppearanceEdge) -> CGRect? {
        @Dependency(\.uiApplication.mainWindow) var mainWindow: UIWindow?
        guard let mainWindow else { return nil }

        let size: CGSize = .init(
            width: mainWindow.bounds.width,
            height: mainWindow.bounds.height / 8
        )

        let bottomSafeAreaInsets = mainWindow.safeAreaInsets.bottom < 30 ? (30 + (30 - mainWindow.safeAreaInsets.bottom)) : mainWindow.safeAreaInsets.bottom
        let topSafeAreaInsets = mainWindow.safeAreaInsets.top < 30 ? (30 + (30 - mainWindow.safeAreaInsets.top)) : mainWindow.safeAreaInsets.top

        var bottomEdgeOrigin: CGPoint = .init(
            x: 0,
            y: mainWindow.bounds.maxY - (size.height + bottomSafeAreaInsets + keyboardHeight)
        )

        let topEdgeOrigin: CGPoint = .init(
            x: 0,
            y: topSafeAreaInsets
        )

        if keyboardHeight > 0 {
            bottomEdgeOrigin.y += 30
        }

        return .init(origin: appearanceEdge == .bottom ? bottomEdgeOrigin : topEdgeOrigin, size: size)
    }

    private static func _show(
        _ toast: Toast,
        onTap: (@Sendable () -> Void)? = nil
    ) {
        // Return early if same toast is already being shown.
        guard !(
            Observables.rootViewToast.value == toast &&
                (Observables.rootViewToastAction.value == nil) == (onTap == nil)
        ) else { return }

        guard !UIApplication.isBlockingUserInteraction,
              !isShowingToast else {
            Task.delayed(
                by: UIApplication.isBlockingUserInteraction ? .milliseconds(100) : .seconds(1)
            ) { @MainActor in
                show(
                    toast,
                    onTap: onTap
                )
            }
            return
        }

        guard UIApplication.iOS27IsAvailable else {
            Observables.rootViewToast.value = toast
            Observables.rootViewToastAction.value = onTap
            return
        }

        @Dependency(\.uiApplication.mainWindow) var mainWindow: UIWindow?

        guard let rootOverlayWindow = mainWindow?.firstSubview(for: "ROOT_OVERLAY_WINDOW"),
              let overlayFrame = frame(toast.type.appearanceEdge ?? .top) else { return }

        func setUpView() {
            Observables.rootViewToast.value = toast
            Observables.rootViewToastAction.value = onTap

            rootOverlayWindow.frame = overlayFrame
            rootOverlayWindow.isUserInteractionEnabled = true

            isHidden = false
        }

        guard BuildInfoOverlay.isHidden else {
            BuildInfoOverlay.hide(persistSetting: false)
            Task.delayed(by: .milliseconds(500)) { @MainActor in
                setUpView()
            }
            return
        }

        setUpView()
    }
}

private extension [Translation] {
    /// - Returns: If a matching output is not found within the array, the provided input string.
    func firstOutput(matching inputString: String) -> String {
        (first(where: { $0.input.value == inputString })?.output ?? inputString).sanitized
    }
}
