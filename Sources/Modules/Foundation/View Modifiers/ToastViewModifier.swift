//
//  ToastViewModifier.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

private struct ToastViewModifier: ViewModifier {
    // MARK: - Constants Accessors

    private typealias Floats = FoundationConstants.CGFloats.ToastView

    // MARK: - Dependencies

    @Dependency(\.coreKit.gcd) private var coreGCD: CoreKit.GCD

    // MARK: - Properties

    @State private var appearanceEdge: Toast.AppearanceEdge?
    @State private var dismissWorkItem: DispatchWorkItem?
    private var onTap: (() -> Void)?
    @Binding private var toast: Toast?

    // MARK: - Init

    public init(_ toast: Binding<Toast?>, onTap: (() -> Void)?) {
        _toast = toast
        self.onTap = onTap
    }

    // MARK: - Body

    public func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                ZStack {
                    withOffset(toastView)
                        .onSwipe(toast?.type.appearanceEdge == .bottom ? .down : .up) {
                            dismiss()
                        }
                }
                .animation(
                    .spring().speed(UIApplication.iOS19IsAvailable ? 1.5 : 1),
                    value: toast
                )
            )
            .onChange(of: toast) { oldValue, newValue in
                present()
                guard UIApplication.iOS19IsAvailable,
                      appearanceEdge == nil,
                      let toast = oldValue ?? newValue else { return }
                appearanceEdge = toast.type.appearanceEdge ?? appearanceEdge
            }
    }

    @ViewBuilder
    private var toastView: some View {
        if let toast {
            VStack {
                if toast.type.appearanceEdge == .bottom {
                    Spacer()
                }

                ToastView(
                    toast.type,
                    title: toast.title,
                    message: toast.message,
                    onTap: onTap
                ) {
                    dismiss()
                }

                if toast.type.appearanceEdge == .top {
                    Spacer()
                }
            }
            .transition(.move(edge: toast.type.appearanceEdge == .bottom ? .bottom : .top))
        }
    }

    // MARK: - Auxiliary

    private func dismiss() {
        withAnimation { toast = nil }
        if UIApplication.iOS19IsAvailable {
            Task.delayed(by: .seconds(1)) { Toast.hide() }
        }

        dismissWorkItem?.cancel()
        dismissWorkItem = nil
    }

    private func present() {
        guard let toast else { return }

        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        dismissWorkItem?.cancel()

        switch toast.perpetuation {
        case let .ephemeral(duration):
            let dismissTask: DispatchWorkItem = .init { dismiss() }
            dismissWorkItem = dismissTask
            coreGCD.after(duration) { dismissTask.perform() }
        default: ()
        }
    }

    private func padding(_ toast: Toast?) -> CGFloat {
        var padding: CGFloat = 0
        guard let appearanceEdge else { return padding }
        switch appearanceEdge {
        case .bottom: padding = Floats.bottomAppearanceEdgePadding
        case .top: padding = Floats.topAppearanceEdgePadding
        }
        return toast == nil ? -padding : padding
    }

    @ViewBuilder
    private func withOffset(_ toastView: some View) -> some View {
        if UIApplication.iOS19IsAvailable {
            toastView
                .padding(appearanceEdge == .top ? .top : .bottom, padding(toast))
        } else {
            toastView
                .offset(y: toast?.type.appearanceEdge == .bottom ? Floats.bottomAppearanceEdgeYOffset : Floats.topAppearanceEdgeYOffset)
        }
    }
}

public extension View {
    func toast(_ toast: Binding<Toast?>, onTap: (() -> Void)? = nil) -> some View {
        modifier(ToastViewModifier(toast, onTap: onTap))
    }
}
