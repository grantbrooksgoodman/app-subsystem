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
    func animationHorizontalCirclesPulse(_ view: UIView) {
        let width = view.frame.size.width
        let height = view.frame.size.height

        let spacing = 3.0
        let radius = (width - spacing * 2) / 3
        let center = CGPoint(
            x: radius / 2,
            y: radius / 2
        )

        let positionY = (height - radius) / 2

        let beginTime = CACurrentMediaTime()
        let beginTimes = [0.36, 0.24, 0.12]
        let timingFunction = CAMediaTimingFunction(
            controlPoints: 0.2,
            0.68,
            0.18,
            1.08
        )

        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.keyTimes = [0, 0.5, 1]
        animation.timingFunctions = [timingFunction, timingFunction]
        animation.values = [1, 0.3, 1]
        animation.duration = 1
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false

        let path = UIBezierPath(
            arcCenter: center,
            radius: radius / 2,
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: false
        )

        for i in 0 ..< 3 {
            let layer = CAShapeLayer()
            layer.frame = CGRect(
                x: (radius + spacing) * CGFloat(i),
                y: positionY,
                width: radius,
                height: radius
            )

            layer.path = path.cgPath
            layer.fillColor = colorAnimation.cgColor

            animation.beginTime = beginTime - beginTimes[i]

            layer.add(
                animation,
                forKey: "animation"
            )

            view.layer.addSublayer(layer)
        }
    }

    func animationLineScaling(_ view: UIView) {
        let width = view.frame.size.width
        let height = view.frame.size.height

        let lineWidth = width / 9

        let beginTime = CACurrentMediaTime()
        let beginTimes = [0.5, 0.4, 0.3, 0.2, 0.1]
        let timingFunction = CAMediaTimingFunction(
            controlPoints: 0.2,
            0.68,
            0.18,
            1.08
        )

        let animation = CAKeyframeAnimation(keyPath: "transform.scale.y")
        animation.keyTimes = [0, 0.5, 1]
        animation.timingFunctions = [timingFunction, timingFunction]
        animation.values = [1, 0.4, 1]
        animation.duration = 1
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false

        let path = UIBezierPath(
            roundedRect: CGRect(
                x: 0,
                y: 0,
                width: lineWidth,
                height: height
            ),
            cornerRadius: width / 2
        )

        for i in 0 ..< 5 {
            let layer = CAShapeLayer()
            layer.frame = CGRect(
                x: lineWidth * 2 * CGFloat(i),
                y: 0,
                width: lineWidth,
                height: height
            )

            layer.path = path.cgPath
            layer.backgroundColor = nil
            layer.fillColor = colorAnimation.cgColor

            animation.beginTime = beginTime - beginTimes[i]

            layer.add(
                animation,
                forKey: "animation"
            )

            view.layer.addSublayer(layer)
        }
    }

    func animationMultipleCirclePulse(_ view: UIView) {
        let width = view.frame.size.width
        let height = view.frame.size.height
        let center = CGPoint(
            x: width / 2,
            y: height / 2
        )

        let radius = width / 2

        let duration = 1.0
        let beginTime = CACurrentMediaTime()
        let beginTimes = [0, 0.3, 0.6]

        let animationScale = CABasicAnimation(keyPath: "transform.scale")
        animationScale.duration = duration
        animationScale.fromValue = 0
        animationScale.toValue = 1

        let animationOpacity = CAKeyframeAnimation(keyPath: "opacity")
        animationOpacity.duration = duration
        animationOpacity.keyTimes = [0, 0.05, 1]
        animationOpacity.values = [0, 1, 0]

        let animation = CAAnimationGroup()
        animation.animations = [animationScale, animationOpacity]
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = duration
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false

        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: false
        )

        for i in 0 ..< 3 {
            let layer = CAShapeLayer()
            layer.frame = CGRect(
                x: 0,
                y: 0,
                width: width,
                height: height
            )

            layer.path = path.cgPath
            layer.fillColor = colorAnimation.cgColor
            layer.opacity = 0

            animation.beginTime = beginTime + beginTimes[i]

            layer.add(
                animation,
                forKey: "animation"
            )

            view.layer.addSublayer(layer)
        }
    }

    func animationSingleCirclePulse(_ view: UIView) {
        let width = view.frame.size.width
        let height = view.frame.size.height
        let center = CGPoint(
            x: width / 2,
            y: height / 2
        )

        let radius = width / 2

        let duration = 1.0

        let animationScale = CABasicAnimation(keyPath: "transform.scale")
        animationScale.duration = duration
        animationScale.fromValue = 0
        animationScale.toValue = 1

        let animationOpacity = CABasicAnimation(keyPath: "opacity")
        animationOpacity.duration = duration
        animationOpacity.fromValue = 1
        animationOpacity.toValue = 0

        let animation = CAAnimationGroup()
        animation.animations = [animationScale, animationOpacity]
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.duration = duration
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false

        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: false
        )

        let layer = CAShapeLayer()
        layer.frame = CGRect(
            x: 0,
            y: 0,
            width: width,
            height: height
        )

        layer.path = path.cgPath
        layer.fillColor = colorAnimation.cgColor

        layer.add(
            animation,
            forKey: "animation"
        )

        view.layer.addSublayer(layer)
    }
}
