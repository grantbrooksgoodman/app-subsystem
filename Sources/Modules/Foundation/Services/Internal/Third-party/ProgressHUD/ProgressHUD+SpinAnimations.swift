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
    func animationCircleRotateChase(_ view: UIView) {
        let width = view.frame.size.width
        let height = view.frame.size.height
        let center1 = CGPoint(
            x: width / 2,
            y: height / 2
        )

        let spacing = 3.0
        let radius = (width - 4 * spacing) / 4
        let center2 = CGPoint(
            x: radius / 2,
            y: radius / 2
        )

        let duration = 1.5

        let path1 = UIBezierPath(
            arcCenter: center1,
            radius: radius * 2,
            startAngle: 1.5 * .pi,
            endAngle: 3.5 * .pi,
            clockwise: true
        )

        let path2 = UIBezierPath(
            arcCenter: center2,
            radius: radius / 2,
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: false
        )

        for i in 0 ..< 5 {
            let rate = Float(i) * 1 / 5
            let fromScale = 1 - rate
            let toScale = 0.2 + rate

            let animationScale = CABasicAnimation(keyPath: "transform.scale")
            animationScale.duration = duration
            animationScale.repeatCount = .infinity
            animationScale.fromValue = fromScale
            animationScale.toValue = toScale

            let animationPosition = CAKeyframeAnimation(keyPath: "position")
            animationPosition.duration = duration
            animationPosition.repeatCount = .infinity
            animationPosition.path = path1.cgPath

            let animation = CAAnimationGroup()
            animation.animations = [animationScale, animationPosition]
            animation.timingFunction = CAMediaTimingFunction(
                controlPoints: 0.5,
                0.15 + rate,
                0.25,
                1
            )

            animation.duration = duration
            animation.repeatCount = .infinity
            animation.isRemovedOnCompletion = false

            let layer = CAShapeLayer()
            layer.frame = CGRect(
                x: 0,
                y: 0,
                width: radius,
                height: radius
            )

            layer.path = path2.cgPath
            layer.fillColor = colorAnimation.cgColor

            layer.add(
                animation,
                forKey: "animation"
            )

            view.layer.addSublayer(layer)
        }
    }

    func animationCircleSpinFade(_ view: UIView) {
        let width = view.frame.size.width

        let spacing = 3.0
        let radius = (width - 4 * spacing) / 3.5
        let radiusX = (width - radius) / 2
        let center = CGPoint(
            x: radius / 2,
            y: radius / 2
        )

        let duration = 1.0
        let beginTime = CACurrentMediaTime()
        let beginTimes: [CFTimeInterval] = [0.84, 0.72, 0.6, 0.48, 0.36, 0.24, 0.12, 0]

        let animationScale = CAKeyframeAnimation(keyPath: "transform.scale")
        animationScale.keyTimes = [0, 0.5, 1]
        animationScale.values = [1, 0.4, 1]
        animationScale.duration = duration

        let animationOpacity = CAKeyframeAnimation(keyPath: "opacity")
        animationOpacity.keyTimes = [0, 0.5, 1]
        animationOpacity.values = [1, 0.3, 1]
        animationOpacity.duration = duration

        let animation = CAAnimationGroup()
        animation.animations = [animationScale, animationOpacity]
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = duration
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false

        let path = UIBezierPath(
            arcCenter: center,
            radius: radius / 2,
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: false
        )

        for i in 0 ..< 8 {
            let angle = .pi / 4 * CGFloat(i)

            let layer = CAShapeLayer()
            layer.path = path.cgPath
            layer.fillColor = colorAnimation.cgColor
            layer.backgroundColor = nil
            layer.frame = CGRect(
                x: radiusX * (cos(angle) + 1),
                y: radiusX * (sin(angle) + 1),
                width: radius,
                height: radius
            )

            animation.beginTime = beginTime - beginTimes[i]

            layer.add(
                animation,
                forKey: "animation"
            )

            view.layer.addSublayer(layer)
        }
    }

    func animationCircleStrokeSpin(_ view: UIView) {
        let width = view.frame.size.width
        let height = view.frame.size.height
        let center = CGPoint(
            x: width / 2,
            y: height / 2
        )

        let beginTime = 0.5
        let durationStart = 1.2
        let durationStop = 0.7

        let animationRotation = CABasicAnimation(keyPath: "transform.rotation")
        animationRotation.byValue = 2 * Float.pi
        animationRotation.timingFunction = CAMediaTimingFunction(name: .linear)

        let animationStart = CABasicAnimation(keyPath: "strokeStart")
        animationStart.duration = durationStart
        animationStart.timingFunction = CAMediaTimingFunction(
            controlPoints: 0.4,
            0,
            0.2,
            1
        )

        animationStart.fromValue = 0
        animationStart.toValue = 1
        animationStart.beginTime = beginTime

        let animationStop = CABasicAnimation(keyPath: "strokeEnd")
        animationStop.duration = durationStop
        animationStop.timingFunction = CAMediaTimingFunction(
            controlPoints: 0.4,
            0,
            0.2,
            1
        )

        animationStop.fromValue = 0
        animationStop.toValue = 1

        let animation = CAAnimationGroup()
        animation.animations = [animationRotation, animationStop, animationStart]
        animation.duration = durationStart + beginTime
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards

        let path = UIBezierPath(
            arcCenter: center,
            radius: width / 2,
            startAngle: -0.5 * .pi,
            endAngle: 1.5 * .pi,
            clockwise: true
        )

        let layer = CAShapeLayer()
        layer.frame = CGRect(
            x: 0,
            y: 0,
            width: width,
            height: height
        )

        layer.path = path.cgPath
        layer.fillColor = nil
        layer.strokeColor = colorAnimation.cgColor
        layer.lineWidth = 3

        layer.add(
            animation,
            forKey: "animation"
        )

        view.layer.addSublayer(layer)
    }

    func animationLineSpinFade(_ view: UIView) {
        let width = view.frame.size.width
        let height = view.frame.size.height

        let spacing = 3.0
        let lineWidth = (width - 4 * spacing) / 5
        let lineHeight = (height - 2 * spacing) / 3
        let containerSize = max(
            lineWidth,
            lineHeight
        )

        let radius = width / 2 - containerSize / 2

        let duration = 1.2
        let beginTime = CACurrentMediaTime()
        let beginTimes: [CFTimeInterval] = [0.96, 0.84, 0.72, 0.6, 0.48, 0.36, 0.24, 0.12]
        let timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let animation = CAKeyframeAnimation(keyPath: "opacity")
        animation.keyTimes = [0, 0.5, 1]
        animation.timingFunctions = [timingFunction, timingFunction]
        animation.values = [1, 0.3, 1]
        animation.duration = duration
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false

        let path = UIBezierPath(
            roundedRect: CGRect(
                x: 0,
                y: 0,
                width: lineWidth,
                height: lineHeight
            ),
            cornerRadius: lineWidth / 2
        )

        for i in 0 ..< 8 {
            let angle = .pi / 4 * CGFloat(i)

            let line = CAShapeLayer()
            line.frame = CGRect(
                x: (containerSize - lineWidth) / 2,
                y: (containerSize - lineHeight) / 2,
                width: lineWidth,
                height: lineHeight
            )

            line.path = path.cgPath
            line.backgroundColor = nil
            line.fillColor = colorAnimation.cgColor

            let container = CALayer()
            container.frame = CGRect(
                x: radius * (cos(angle) + 1),
                y: radius * (sin(angle) + 1),
                width: containerSize,
                height: containerSize
            )

            container.addSublayer(line)
            container.sublayerTransform = CATransform3DMakeRotation(
                .pi / 2 + angle,
                0,
                0,
                1
            )

            animation.beginTime = beginTime - beginTimes[i]

            container.add(
                animation,
                forKey: "animation"
            )

            view.layer.addSublayer(container)
        }
    }

    func animationSystemActivityIndicator(_ view: UIView) {
        let spinner = UIActivityIndicatorView(style: .large)
        let scale = view.frame.size.width / spinner.frame.size.width
        spinner.transform = CGAffineTransform(
            scaleX: scale,
            y: scale
        )

        spinner.frame = view.bounds
        spinner.color = colorAnimation
        spinner.hidesWhenStopped = true
        spinner.startAnimating()
        view.addSubview(spinner)
    }
}
