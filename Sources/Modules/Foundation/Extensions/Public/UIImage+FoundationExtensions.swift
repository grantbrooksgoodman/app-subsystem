//
//  UIImage+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

public extension UIImage {
    // MARK: - Properties

    static var appIcon: UIImage? {
        get async {
            let utility = AppIconImageUtility.shared
            return (await utility.remoteAppIconImage) ?? utility.localAppIconImage
        }
    }

    // MARK: - Methods

    static func downloadedFrom(_ link: String) async -> UIImage? {
        guard let url = URL(string: link) else { return nil }
        return await downloadedFrom(url)
    }

    static func downloadedFrom(_ url: URL) async -> UIImage? {
        @Dependency(\.urlSession) var urlSession: URLSession

        guard let response = try? await urlSession.data(from: url),
              let image = UIImage(data: response.0) else { return nil }
        return image
    }

    static func downloadedFrom(_ link: String, completion: @escaping (_ image: UIImage?) -> Void) {
        guard let url = URL(string: link) else {
            completion(nil)
            return
        }

        downloadedFrom(url) { image in
            completion(image)
        }
    }

    static func downloadedFrom(_ url: URL, completion: @escaping (_ image: UIImage?) -> Void) {
        @Dependency(\.urlSession) var urlSession: URLSession

        urlSession.dataTask(with: url) { data, _, _ in
            guard let data,
                  let image = UIImage(data: data) else {
                completion(nil)
                return
            }

            completion(image)
        }.resume()
    }
}

public extension UIImage? {
    var swiftUIImage: Image? {
        guard let self else { return nil }
        return .init(uiImage: self)
    }
}
