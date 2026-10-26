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

extension ProgressHUD {
    enum AnimationType: CaseIterable {
        case circleRotateChase
        case circleSpinFade
        case circleStrokeSpin
        case horizontalCirclesPulse
        case lineScaling
        case lineSpinFade
        case multipleCirclePulse
        case multipleCircleScaleRipple
        case none
        case singleCirclePulse
        case singleCircleScaleRipple
        case systemActivityIndicator
    }
}
