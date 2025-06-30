//
//  ForcedUpdateModalPageViewService.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import UIKit

struct ForcedUpdateModalPageViewService {
    // MARK: - Dependencies

    @Dependency(\.mainBundle) private var mainBundle: Bundle
    @Dependency(\.urlSession) private var urlSession: URLSession

    // MARK: - Properties

    var localAppIconImage: UIImage? { getLocalAppIconImage() }
    var remoteAppIconImage: UIImage? {
        get async { try? await getRemoteAppIconImage().get() }
    }

    // MARK: - Methods

    private func getLocalAppIconImage() -> UIImage? {
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

        guard let iconsDictionary = mainBundle.infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIcon = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String] else { return nil }

        let images = iconFiles.compactMap(UIImage.init(named:))
        guard let largestImage = images.max(by: { $0.pixelCount < $1.pixelCount }) else { return nil }
        return upscale(largestImage, by: 2)
    }

    private func getRemoteAppIconImage() async -> Callback<UIImage, Exception> {
        await withCheckedContinuation { continuation in
            getRemoteAppIconImage { callback in
                continuation.resume(returning: callback)
            }
        }
    }

    private func getRemoteAppIconImage(completion: @escaping (Callback<UIImage, Exception>) -> Void) {
        guard let bundleIdentifier = mainBundle.bundleIdentifier,
              let lookupURL = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleIdentifier)") else {
            return completion(.failure(.init(
                "Failed to resolve bundle identifier and/or lookup URL.",
                metadata: [self, #file, #function, #line]
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
                        metadata: [self, #file, #function, #line]
                    ) : .init(error, metadata: [self, #file, #function, #line])
                ))
            }

            urlSession.dataTask(with: highResolutionURL) { data, _, error in
                guard let image = data.flatMap({ UIImage(data: $0) }) else {
                    return completion(.failure(
                        error == nil ? .init(
                            "Failed to resolve high resolution image.",
                            metadata: [self, #file, #function, #line]
                        ) : .init(error, metadata: [self, #file, #function, #line])
                    ))
                }

                return completion(.success(image))
            }.resume()
        }.resume()
    }
}

private extension UIImage {
    var pixelCount: CGFloat { (size.width * scale) * (size.height * scale) }
}
