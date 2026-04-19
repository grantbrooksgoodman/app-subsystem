//
//  UIViewController+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

public extension UIViewController {
    // MARK: - Properties

    /// A string describing the view controller's type.
    var descriptor: String { .init(type(of: self)) }

    /// The deepest child view controller in the hierarchy.
    var leafViewController: UIViewController {
        descendants(type: UIViewController.self).last ?? self
    }

    // MARK: - Methods

    /// Returns all ancestor view controllers matching the given
    /// type.
    func ancestors<T>(type: T.Type? = nil) -> [T] {
        let rootParent = parent
        return sequence(first: rootParent) { $0?.parent }.compactMap { $0 as? T }
    }

    /// Returns all descendant view controllers matching the given
    /// type.
    func descendants<T>(type: T.Type? = nil) -> [T] {
        children.compactMap { child in
            var result = (child as? T).map { [$0] } ?? []
            result += child.descendants(type: type)
            return result
        }.flatMap { $0 }
    }
}
