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
    enum AlertIcon: CaseIterable {
        // MARK: - Cases

        case bolt
        case bookmark
        case card
        case cart
        case dislike
        case doc
        case eject
        case exclamation
        case flag
        case heart
        case like
        case message
        case moon
        case privacy
        case question
        case rotate
        case search
        case shuffle
        case star

        // MARK: - Properties

        var image: UIImage? {
            switch self {
            case .bolt: UIImage(systemName: "bolt.fill")
            case .bookmark: UIImage(systemName: "bookmark.fill")
            case .card: UIImage(systemName: "creditcard.fill")
            case .cart: UIImage(systemName: "cart.fill")
            case .dislike: UIImage(systemName: "hand.thumbsdown.fill")
            case .doc: UIImage(systemName: "doc.fill")
            case .eject: UIImage(systemName: "eject.fill")
            case .exclamation: UIImage(systemName: "exclamationmark.triangle.fill")
            case .flag: UIImage(systemName: "flag.fill")
            case .heart: UIImage(systemName: "heart.fill")
            case .like: UIImage(systemName: "hand.thumbsup.fill")
            case .message: UIImage(systemName: "envelope.fill")
            case .moon: UIImage(systemName: "moon.fill")
            case .privacy: UIImage(systemName: "hand.raised.fill")
            case .question: UIImage(systemName: "questionmark.diamond.fill")
            case .rotate: UIImage(systemName: "rotate.right.fill")
            case .search: UIImage(systemName: "magnifyingglass")
            case .shuffle: UIImage(systemName: "shuffle")
            case .star: UIImage(systemName: "star.fill")
            }
        }
    }
}
