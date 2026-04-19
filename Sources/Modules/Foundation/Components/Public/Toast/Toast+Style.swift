//
//  Toast+Style.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

public extension Toast {
    /// The semantic style of a toast, which determines its icon and
    /// default color.
    ///
    /// Each case carries a predefined system image name and accent
    /// color appropriate for the severity it represents. Use ``none``
    /// when the toast does not require an icon.
    enum Style: Equatable, Sendable {
        // MARK: - Cases

        /// An error condition that requires the user's attention.
        case error

        /// A neutral informational message.
        case info

        /// A confirmation that an operation completed successfully.
        case success

        /// A cautionary notice.
        case warning

        /// No semantic style. The toast displays without an icon.
        case none

        // MARK: - Constants Accessors

        private typealias Colors = FoundationConstants.Colors.ToastView
        private typealias Strings = FoundationConstants.Strings.ToastView

        // MARK: - Properties

        var bannerIconSystemImageName: String? {
            switch self {
            case .error: Strings.bannerErrorIconImageSystemName
            case .info: Strings.bannerInfoIconImageSystemName
            case .success: Strings.bannerSuccessIconImageSystemName
            case .warning: Strings.bannerWarningIconImageSystemName
            case .none: nil
            }
        }

        var capsuleIconSystemImageName: String? {
            switch self {
            case .error: Strings.capsuleErrorIconImageSystemName
            case .info: Strings.capsuleInfoIconImageSystemName
            case .success: Strings.capsuleSuccessIconImageSystemName
            case .warning: Strings.capsuleWarningIconImageSystemName
            case .none: nil
            }
        }

        var defaultColor: Color? {
            switch self {
            case .error: Colors.defaultErrorColor
            case .info: Colors.defaultInfoColor
            case .success: Colors.defaultSuccessColor
            case .warning: Colors.defaultWarningColor
            case .none: nil
            }
        }
    }
}
