//
//  AppIconImageUtility.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

final class AppIconImageUtility {
    // MARK: - Types

    private enum CacheKey: String, CaseIterable {
        case localAppIconImage
        case remoteAppIconImage
    }

    // MARK: - Properties

    static let shared = AppIconImageUtility()

    @Cached(CacheKey.localAppIconImage) private var cachedLocalAppIconImage: UIImage?
    @Cached(CacheKey.remoteAppIconImage) private var cachedRemoteAppIconImage: UIImage?

    // MARK: - Computed Properties

    var localAppIconImage: UIImage? { getLocalAppIconImage() }
    var remoteAppIconImage: UIImage? {
        get async { try? await getRemoteAppIconImage().get() }
    }

    // MARK: - Init

    private init() {}

    // MARK: - Computed Property Getters

    private func getLocalAppIconImage() -> UIImage? {
        @Dependency(\.mainBundle) var mainBundle: Bundle
        func upscale(_ image: UIImage, by scaleFactor: CGFloat) -> UIImage? {
            guard let input = CIImage(image: image),
                  let coreImageFilter = CIFilter(name: "CILanczosScaleTransform") else { return nil }

            coreImageFilter.setValue(input, forKey: kCIInputImageKey)
            coreImageFilter.setValue(scaleFactor, forKey: kCIInputScaleKey)
            coreImageFilter.setValue(1.0, forKey: kCIInputAspectRatioKey)

            let coreImageContext = CIContext()
            guard let outputImage = coreImageFilter.outputImage,
                  let cgImage = coreImageContext.createCGImage(
                      outputImage,
                      from: outputImage.extent
                  ) else { return nil }

            return .init(
                cgImage: cgImage,
                scale: image.scale,
                orientation: image.imageOrientation
            )
        }

        if let cachedLocalAppIconImage {
            return cachedLocalAppIconImage
        }

        guard let iconsDictionary = mainBundle.infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIcon = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String] else { return nil }

        let images = iconFiles.compactMap(UIImage.init(named:))
        guard let largestImage = images.max(by: { $0.pixelCount < $1.pixelCount }),
              let upscaledImage = upscale(largestImage, by: 2) else { return nil }

        cachedLocalAppIconImage = upscaledImage
        return upscaledImage
    }

    private func getRemoteAppIconImage() async -> Callback<UIImage, Exception> {
        await withCheckedContinuation { continuation in
            getRemoteAppIconImage { callback in
                continuation.resume(returning: callback)
            }
        }
    }

    private func getRemoteAppIconImage(completion: @escaping (Callback<UIImage, Exception>) -> Void) {
        @Dependency(\.mainBundle) var mainBundle: Bundle
        @Dependency(\.urlSession) var urlSession: URLSession

        if let cachedRemoteAppIconImage {
            return completion(.success(cachedRemoteAppIconImage))
        }

        guard let bundleIdentifier = mainBundle.bundleIdentifier,
              let lookupURL = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleIdentifier)") else {
            return completion(.failure(.init(
                "Failed to resolve bundle identifier and/or lookup URL.",
                metadata: .init(sender: self)
            )))
        }

        urlSession.dataTask(with: lookupURL) { data, _, error in
            guard let data,
                  let result = ((try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["results"] as? [[String: Any]])?.first,
                  let artworkURLString = result["artworkUrl100"] as? String,
                  let highResolutionURL = URL(
                      string: artworkURLString.replacingOccurrences(
                          of: "100x100",
                          with: "1024x1024"
                      )
                  ) else {
                return completion(.failure(
                    error == nil ? .init(
                        "Failed to resolve standard resolution image.",
                        metadata: .init(sender: self)
                    ) : .init(error, metadata: .init(sender: self))
                ))
            }

            urlSession.dataTask(with: highResolutionURL) { data, _, error in
                guard let image = data.flatMap(UIImage.init(data:)) else {
                    return completion(.failure(
                        error == nil ? .init(
                            "Failed to resolve high resolution image.",
                            metadata: .init(sender: self)
                        ) : .init(error, metadata: .init(sender: self))
                    ))
                }

                self.cachedRemoteAppIconImage = image
                return completion(.success(image))
            }.resume()
        }.resume()
    }

    // MARK: - Clear Cache

    func clearCache() {
        cachedLocalAppIconImage = nil
        cachedRemoteAppIconImage = nil
    }
}

private extension UIImage {
    var pixelCount: CGFloat { (size.width * scale) * (size.height * scale) }
}
