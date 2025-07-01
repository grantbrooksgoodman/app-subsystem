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

    /// Recursively resolves the last child view controller among its `children` in the view controller hierarchy.
    var leafViewController: UIViewController {
        descendants(type: UIViewController.self).last ?? self
    }

    // MARK: - Methods

    /// Recursively traverses the view controller hirearchy and returns all parents matching the provided `type`.
    func ancestors<T>(type: T.Type? = nil) -> [T] {
        let rootParent = parent
        return sequence(first: rootParent) { $0?.parent }.compactMap { $0 as? T }
    }

    /// Recursively traverses the view controller hirearchy and returns all children matching the provided `type`.
    func descendants<T>(type: T.Type? = nil) -> [T] {
        children.compactMap { child in
            var result = (child as? T).map { [$0] } ?? []
            result += child.descendants(type: type)
            return result
        }.flatMap { $0 }
    }
}
