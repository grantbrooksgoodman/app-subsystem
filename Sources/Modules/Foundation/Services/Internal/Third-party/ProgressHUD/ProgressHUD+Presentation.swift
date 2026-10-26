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
    // MARK: - Methods

    static func dismiss() {
        DispatchQueue.main.async {
            shared.dismissHUD()
        }
    }

    static func remove() {
        DispatchQueue.main.async {
            shared.removeHUD()
        }
    }

    static func show(
        _ text: String? = nil,
        icon: AlertIcon,
        interaction: Bool = true,
        delay: TimeInterval? = nil
    ) {
        present(
            tintedImageContent(icon.image),
            text: text,
            interaction: interaction,
            delay: delay
        )
    }

    static func show(
        _ text: String? = nil,
        icon: AnimatedIcon,
        interaction: Bool = true,
        delay: TimeInterval? = nil
    ) {
        present(
            .animatedIcon(icon),
            text: text,
            interaction: interaction,
            delay: delay
        )
    }

    static func show(
        _ text: String? = nil,
        interaction: Bool = true
    ) {
        present(
            .animation,
            text: text,
            interaction: interaction
        )
    }

    static func show(
        _ text: String? = nil,
        symbol: String,
        interaction: Bool = true,
        delay: TimeInterval? = nil
    ) {
        present(
            tintedImageContent(UIImage(systemName: symbol)),
            text: text,
            interaction: interaction,
            delay: delay
        )
    }

    static func showAdded(
        _ text: String? = nil,
        interaction: Bool = true,
        delay: TimeInterval? = nil
    ) {
        present(
            .animatedIcon(.added),
            text: text,
            interaction: interaction,
            delay: delay
        )
    }

    static func showError(
        _ error: Error?,
        image: UIImage? = nil,
        interaction: Bool = true,
        delay: TimeInterval? = nil
    ) {
        present(
            .staticImage(image ?? imageError),
            text: error?.localizedDescription,
            interaction: interaction,
            delay: delay
        )
    }

    static func showError(
        _ text: String? = nil,
        image: UIImage? = nil,
        interaction: Bool = true,
        delay: TimeInterval? = nil
    ) {
        present(
            .staticImage(image ?? imageError),
            text: text,
            interaction: interaction,
            delay: delay
        )
    }

    static func showFailed(
        _ error: Error?,
        interaction: Bool = true,
        delay: TimeInterval? = nil
    ) {
        present(
            .animatedIcon(.failed),
            text: error?.localizedDescription,
            interaction: interaction,
            delay: delay
        )
    }

    static func showFailed(
        _ text: String? = nil,
        interaction: Bool = true,
        delay: TimeInterval? = nil
    ) {
        present(
            .animatedIcon(.failed),
            text: text,
            interaction: interaction,
            delay: delay
        )
    }

    static func showProgress(
        _ progress: CGFloat,
        interaction: Bool = false
    ) {
        present(
            .progress(progress),
            text: nil,
            interaction: interaction
        )
    }

    static func showProgress(
        _ text: String?,
        _ progress: CGFloat,
        interaction: Bool = false
    ) {
        present(
            .progress(progress),
            text: text,
            interaction: interaction
        )
    }

    static func showSucceed(
        _ text: String? = nil,
        interaction: Bool = true,
        delay: TimeInterval? = nil
    ) {
        present(
            .animatedIcon(.succeed),
            text: text,
            interaction: interaction,
            delay: delay
        )
    }

    static func showSuccess(
        _ text: String? = nil,
        image: UIImage? = nil,
        interaction: Bool = true,
        delay: TimeInterval? = nil
    ) {
        present(
            .staticImage(image ?? imageSuccess),
            text: text,
            interaction: interaction,
            delay: delay
        )
    }

    // MARK: - Auxiliary

    private static func present(
        _ content: Content,
        text: String?,
        interaction: Bool,
        delay: TimeInterval? = nil
    ) {
        DispatchQueue.main.async {
            shared.setup(
                text: text,
                content: content,
                interaction: interaction,
                delay: delay
            )
        }
    }

    private static func tintedImageContent(_ image: UIImage?) -> Content {
        guard let image else { return .animation }
        return .staticImage(
            image.withTintColor(
                colorAnimation,
                renderingMode: .alwaysOriginal
            )
        )
    }
}
