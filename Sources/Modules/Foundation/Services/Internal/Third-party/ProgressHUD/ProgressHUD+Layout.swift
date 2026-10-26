//
// Copyright (c) 2023 Related Code - https://relatedcode.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

/* Native */
import Foundation
import UIKit

extension ProgressHUD {
    // MARK: - Methods

    @objc
    func setupPosition(
        _ notification: Notification? = nil
    ) {
        let userInfo = notification?.userInfo
        let heightKeyboard: CGFloat = switch notification?.name {
        case UIResponder.keyboardDidHideNotification,
             UIResponder.keyboardWillHideNotification:
            0

        case UIResponder.keyboardDidShowNotification,
             UIResponder.keyboardWillShowNotification:
            (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.size.height ?? 0

        default:
            keyboardHeight()
        }

        let screen = (UIApplication.shared.windows.first ?? UIWindow()).bounds
        UIView.animate(
            withDuration: userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0,
            delay: 0,
            options: .allowUserInteraction,
            animations: { [self] in
                toolbarHUD?.center = CGPoint(
                    x: screen.size.width / 2,
                    y: (screen.size.height - heightKeyboard) / 2
                )

                viewBackground?.frame = screen
            },
            completion: nil
        )
    }

    func setupSizes(
        text: String?,
        content: Content
    ) {
        guard let text else {
            return setupSizesTextNone()
        }

        if case .animation = content,
           animationType == .none {
            setupSizesTextOnly(text)
        } else {
            setupSizesBoth(text)
        }
    }

    // MARK: - Auxiliary

    private func keyboardHeight() -> CGFloat {
        guard let keyboardWindowClass = NSClassFromString("UIRemoteKeyboardWindow"),
              let inputSetContainerViewClass = NSClassFromString("UIInputSetContainerView"),
              let inputSetHostViewClass = NSClassFromString("UIInputSetHostView") else { return 0 }

        return UIApplication
            .shared
            .windows
            .filter { $0.isKind(of: keyboardWindowClass) }
            .flatMap(\.subviews)
            .filter { $0.isKind(of: inputSetContainerViewClass) }
            .flatMap(\.subviews)
            .first { $0.isKind(of: inputSetHostViewClass) }?
            .frame
            .size
            .height ?? 0
    }

    private func rectText(_ text: String) -> CGRect {
        text.boundingRect(
            with: CGSize(
                width: 250,
                height: 250
            ),
            options: .usesLineFragmentOrigin,
            attributes: [.font: fontStatus],
            context: nil
        )
    }

    private func setupSizes(
        width: CGFloat,
        height: CGFloat,
        center: CGPoint,
        rect: CGRect
    ) {
        toolbarHUD?.bounds = CGRect(
            x: 0,
            y: 0,
            width: ceil(width),
            height: ceil(height)
        )

        viewProgress?.center = center
        viewAnimatedIcon?.center = center
        viewStaticImage?.center = center
        viewAnimation?.center = center

        labelStatus?.frame = rect
    }

    private func setupSizesBoth(_ text: String) {
        var rect = rectText(text)
        let base = mediaSize + 2 * marginSize

        let width = max(
            base,
            rect.size.width + 2 * marginSize
        )

        let height = max(
            base,
            rect.size.height + 2 * marginSize + mediaSize
        )

        rect.origin.x = (width - rect.size.width) / 2
        rect.origin.y = (height - rect.size.height) / 2 + (mediaSize + marginSize) / 2

        setupSizes(
            width: width,
            height: height,
            center: CGPoint(
                x: width / 2,
                y: marginSize + mediaSize / 2
            ),
            rect: rect
        )
    }

    private func setupSizesTextNone() {
        let width = mediaSize + 2 * marginSize
        let height = mediaSize + 2 * marginSize

        setupSizes(
            width: width,
            height: height,
            center: CGPoint(
                x: width / 2,
                y: height / 2
            ),
            rect: .zero
        )
    }

    private func setupSizesTextOnly(_ text: String) {
        var rect = rectText(text)
        let base = mediaSize + 2 * marginSize

        let width = max(
            base,
            rect.size.width + 2 * marginSize
        )

        let height = max(
            base,
            rect.size.height + 2 * marginSize
        )

        rect.origin.x = (width - rect.size.width) / 2
        rect.origin.y = (height - rect.size.height) / 2

        setupSizes(
            width: width,
            height: height,
            center: .zero,
            rect: rect
        )
    }
}
