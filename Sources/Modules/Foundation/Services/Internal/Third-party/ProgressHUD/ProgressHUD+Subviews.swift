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
    // MARK: - Properties

    private var mediaFrame: CGRect {
        CGRect(
            x: 0,
            y: 0,
            width: mediaSize,
            height: mediaSize
        )
    }

    // MARK: - Methods

    func removeAnimatedIcon() {
        viewAnimatedIcon?.removeFromSuperview()
        viewAnimatedIcon = nil
    }

    func removeAnimationView() {
        viewAnimation?.removeFromSuperview()
        viewAnimation = nil
    }

    func removeBackground() {
        viewBackground?.removeFromSuperview()
        viewBackground = nil
    }

    func removeProgressView() {
        viewProgress?.removeFromSuperview()
        viewProgress = nil
    }

    func removeStaticImage() {
        viewStaticImage?.removeFromSuperview()
        viewStaticImage = nil
    }

    func removeStatus() {
        labelStatus?.removeFromSuperview()
        labelStatus = nil
    }

    func removeToolbar() {
        toolbarHUD?.removeFromSuperview()
        toolbarHUD = nil
    }

    func setupAnimatedIcon(_ animatedIcon: AnimatedIcon) {
        if viewAnimatedIcon == nil {
            viewAnimatedIcon = UIView(frame: mediaFrame)
        }

        guard let viewAnimatedIcon else { return }
        if viewAnimatedIcon.superview == nil {
            toolbarHUD?.addSubview(viewAnimatedIcon)
        }

        viewAnimatedIcon.layer.sublayers?.forEach {
            $0.removeFromSuperlayer()
        }

        switch animatedIcon {
        case .added: animatedIconAdded(viewAnimatedIcon)
        case .failed: animatedIconFailed(viewAnimatedIcon)
        case .succeed: animatedIconSucceed(viewAnimatedIcon)
        }
    }

    func setupAnimationView() {
        if viewAnimation == nil {
            viewAnimation = UIView(frame: mediaFrame)
        }

        guard let viewAnimation else { return }
        if viewAnimation.superview == nil {
            toolbarHUD?.addSubview(viewAnimation)
        }

        for subview in viewAnimation.subviews {
            subview.removeFromSuperview()
        }

        viewAnimation.layer.sublayers?.forEach {
            $0.removeFromSuperlayer()
        }

        switch animationType {
        case .circleRotateChase:
            animationCircleRotateChase(viewAnimation)

        case .circleSpinFade:
            animationCircleSpinFade(viewAnimation)

        case .circleStrokeSpin:
            animationCircleStrokeSpin(viewAnimation)

        case .horizontalCirclesPulse:
            animationHorizontalCirclesPulse(viewAnimation)

        case .lineScaling:
            animationLineScaling(viewAnimation)

        case .lineSpinFade:
            animationLineSpinFade(viewAnimation)

        case .multipleCirclePulse:
            animationMultipleCirclePulse(viewAnimation)

        case .multipleCircleScaleRipple:
            animationMultipleCircleScaleRipple(viewAnimation)

        case .none:
            break

        case .singleCirclePulse:
            animationSingleCirclePulse(viewAnimation)

        case .singleCircleScaleRipple:
            animationSingleCircleScaleRipple(viewAnimation)

        case .systemActivityIndicator:
            animationSystemActivityIndicator(viewAnimation)
        }
    }

    func setupBackground(_ interaction: Bool) {
        if viewBackground == nil {
            let viewBackground = UIView(frame: bounds)
            (UIApplication.shared.windows.first ?? UIWindow()).addSubview(viewBackground)
            self.viewBackground = viewBackground
        }

        viewBackground?.backgroundColor = interaction ? .clear : colorBackground
        viewBackground?.isUserInteractionEnabled = !interaction
    }

    func setupProgressView(_ progress: CGFloat) {
        if viewProgress == nil {
            viewProgress = ProgressView(colorProgress)
            viewProgress?.frame = mediaFrame
        }

        guard let viewProgress else { return }
        if viewProgress.superview == nil {
            toolbarHUD?.addSubview(viewProgress)
        }

        viewProgress.setProgress(progress)
    }

    func setupStaticImage(_ staticImage: UIImage) {
        if viewStaticImage == nil {
            viewStaticImage = UIImageView(frame: mediaFrame)
        }

        guard let viewStaticImage else { return }
        if viewStaticImage.superview == nil {
            toolbarHUD?.addSubview(viewStaticImage)
        }

        viewStaticImage.image = staticImage
        viewStaticImage.contentMode = .scaleAspectFit
    }

    func setupStatus(_ text: String?) {
        if labelStatus == nil {
            let labelStatus = UILabel()
            labelStatus.textAlignment = .center
            labelStatus.baselineAdjustment = .alignCenters
            labelStatus.numberOfLines = 0
            toolbarHUD?.addSubview(labelStatus)
            self.labelStatus = labelStatus
        }

        labelStatus?.text = text
        labelStatus?.font = fontStatus
        labelStatus?.textColor = colorStatus
        labelStatus?.isHidden = text == nil
    }

    func setupToolbar() {
        if toolbarHUD == nil {
            let toolbarHUD = UIToolbar(frame: .zero)
            toolbarHUD.isTranslucent = true
            toolbarHUD.clipsToBounds = true
            toolbarHUD.layer.cornerRadius = 10
            toolbarHUD.layer.masksToBounds = true
            viewBackground?.addSubview(toolbarHUD)
            self.toolbarHUD = toolbarHUD
        }

        toolbarHUD?.backgroundColor = colorHUD
    }
}
