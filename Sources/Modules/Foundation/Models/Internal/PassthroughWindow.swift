//
//  PassthroughWindow.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { // swiftlint:disable:next identifier_name
        func _hitTest(_ point: CGPoint, from view: UIView) -> UIView? {
            let convertedPoint = convert(point, to: view)

            guard view.alpha > 0,
                  view.bounds.contains(convertedPoint),
                  !view.isHidden,
                  view.isUserInteractionEnabled else { return nil }

            return view
                .subviews
                .reversed()
                .reduce(UIView?.none) { result, view in
                    result ?? _hitTest(point, from: view)
                } ?? view
        }

        guard #available(iOS 18, *) else {
            guard let hitView = super.hitTest(point, with: event) else { return nil }
            return rootViewController?.view == hitView ? nil : hitView
        }

        guard let hitView = super.hitTest(point, with: event),
              _hitTest(point, from: hitView) != rootViewController?.view else { return nil }
        return hitView
    }
}
