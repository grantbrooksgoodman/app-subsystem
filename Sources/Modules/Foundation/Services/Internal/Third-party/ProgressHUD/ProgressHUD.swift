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

final class ProgressHUD: UIView {
    // MARK: - Types

    enum Content {
        case animatedIcon(AnimatedIcon)
        case animation
        case progress(CGFloat)
        case staticImage(UIImage)
    }

    // MARK: - Properties

    static let shared: ProgressHUD = .init()

    var animationType = AnimationType.systemActivityIndicator
    var colorAnimation = UIColor.lightGray
    var colorBackground = UIColor(
        red: 0,
        green: 0,
        blue: 0,
        alpha: 0.2
    )

    var colorProgress = UIColor.lightGray
    var colorStatus = UIColor.label
    var fontStatus = UIFont.boldSystemFont(ofSize: 24)
    var imageError = UIImage
        .remove
        .withTintColor(
            .systemRed,
            renderingMode: .alwaysOriginal
        )

    var imageSuccess = UIImage
        .checkmark
        .withTintColor(
            .systemGreen,
            renderingMode: .alwaysOriginal
        )

    var labelStatus: UILabel?
    var marginSize: CGFloat = 30
    var mediaSize: CGFloat = 70
    var toolbarHUD: UIToolbar?
    var viewAnimatedIcon: UIView?
    var viewAnimation: UIView?
    var viewBackground: UIView?
    var viewProgress: ProgressView?
    var viewStaticImage: UIImageView?

    private static let observedNotificationNames: [Notification.Name] = [
        UIResponder.keyboardWillShowNotification,
        UIResponder.keyboardWillHideNotification,
        UIResponder.keyboardDidShowNotification,
        UIResponder.keyboardDidHideNotification,
        UIDevice.orientationDidChangeNotification,
    ]

    private var didSetupNotifications = false
    private var timer: Timer?

    // MARK: - Computed Properties

    var colorHUD: UIColor {
        (ThemeService.isDarkModeActive ? UIColor.systemGray4 : .init(hex: 0xE5E5EA))
            .withAlphaComponent(0.99)
    }

    // MARK: - Init

    private convenience init() {
        self.init(frame: UIScreen.main.bounds)
        alpha = 0
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override private init(frame: CGRect) {
        super.init(frame: frame)
    }

    // MARK: - Methods

    func dismissHUD() {
        guard alpha == 1 else { return }

        UIView.animate(
            withDuration: 0.15,
            delay: 0,
            options: [.allowUserInteraction, .curveEaseIn],
            animations: { [self] in
                toolbarHUD?.transform = CGAffineTransform(
                    scaleX: 0.3,
                    y: 0.3
                )

                toolbarHUD?.alpha = 0
            },
            completion: { [self] _ in
                destroyHUD()
                alpha = 0
            }
        )
    }

    func removeHUD() {
        guard alpha == 1 else { return }

        toolbarHUD?.alpha = 0
        destroyHUD()
        alpha = 0
    }

    func setup(
        text: String?,
        content: Content,
        interaction: Bool,
        delay: TimeInterval?
    ) {
        removeDelayTimer()

        setupNotifications()
        setupBackground(interaction)
        setupToolbar()
        setupStatus(text)

        switch content {
        case let .animatedIcon(animatedIcon):
            removeProgressView()
            removeStaticImage()
            removeAnimationView()
            setupAnimatedIcon(animatedIcon)
            setupDelayTimer(
                text: text,
                delay: delay
            )

        case .animation:
            removeProgressView()
            removeAnimatedIcon()
            removeStaticImage()
            setupAnimationView()

        case let .progress(progress):
            removeAnimatedIcon()
            removeStaticImage()
            removeAnimationView()
            setupProgressView(progress)

        case let .staticImage(staticImage):
            removeProgressView()
            removeAnimatedIcon()
            removeAnimationView()
            setupStaticImage(staticImage)
            setupDelayTimer(
                text: text,
                delay: delay
            )
        }

        setupSizes(
            text: text,
            content: content
        )

        setupPosition()
        displayHUD()
    }

    // MARK: - Auxiliary

    private func destroyHUD() {
        removeDelayTimer()
        removeNotifications()

        removeAnimationView()
        removeStaticImage()
        removeAnimatedIcon()
        removeProgressView()

        removeStatus()
        removeToolbar()
        removeBackground()
    }

    private func displayHUD() {
        guard alpha == 0 else { return }

        alpha = 1
        toolbarHUD?.alpha = 0
        toolbarHUD?.transform = CGAffineTransform(
            scaleX: 1.4,
            y: 1.4
        )

        UIView.animate(
            withDuration: 0.15,
            delay: 0,
            options: [.allowUserInteraction, .curveEaseIn],
            animations: { [self] in
                toolbarHUD?.transform = CGAffineTransform(
                    scaleX: 1 / 1.4,
                    y: 1 / 1.4
                )

                toolbarHUD?.alpha = 1
            },
            completion: nil
        )
    }

    private func removeDelayTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func removeNotifications() {
        guard didSetupNotifications else { return }

        for notificationName in Self.observedNotificationNames {
            NotificationCenter.default.removeObserver(
                self,
                name: notificationName,
                object: nil
            )
        }

        didSetupNotifications = false
    }

    private func setupDelayTimer(
        text: String?,
        delay: TimeInterval?
    ) {
        timer = Timer.scheduledTimer(
            withTimeInterval: delay ?? Double(text?.count ?? 0) * 0.03 + 1.25,
            repeats: false
        ) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                self.dismissHUD()
            }
        }
    }

    private func setupNotifications() {
        guard !didSetupNotifications else { return }

        for notificationName in Self.observedNotificationNames {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(setupPosition(_:)),
                name: notificationName,
                object: nil
            )
        }

        didSetupNotifications = true
    }
}
