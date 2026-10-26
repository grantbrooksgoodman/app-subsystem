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
    static var animationType: AnimationType {
        get { shared.animationType }
        set { shared.animationType = newValue }
    }

    static var colorAnimation: UIColor {
        get { shared.colorAnimation }
        set { shared.colorAnimation = newValue }
    }

    static var colorBackground: UIColor {
        get { shared.colorBackground }
        set { shared.colorBackground = newValue }
    }

    static var colorHUD: UIColor {
        shared.colorHUD
    }

    static var colorProgress: UIColor {
        get { shared.colorProgress }
        set { shared.colorProgress = newValue }
    }

    static var colorStatus: UIColor {
        get { shared.colorStatus }
        set { shared.colorStatus = newValue }
    }

    static var fontStatus: UIFont {
        get { shared.fontStatus }
        set { shared.fontStatus = newValue }
    }

    static var imageError: UIImage {
        get { shared.imageError }
        set { shared.imageError = newValue }
    }

    static var imageSuccess: UIImage {
        get { shared.imageSuccess }
        set { shared.imageSuccess = newValue }
    }

    static var marginSize: CGFloat {
        get { shared.marginSize }
        set { shared.marginSize = newValue }
    }

    static var mediaSize: CGFloat {
        get { shared.mediaSize }
        set { shared.mediaSize = newValue }
    }
}
