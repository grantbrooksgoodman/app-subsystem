//
//  MailComposer.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import MessageUI
import UIKit

final class MailComposer: UIViewController, MFMailComposeViewControllerDelegate {
    // MARK: - Types

    struct AttachmentData {
        /* MARK: Properties */

        let data: Data
        let fileName: String
        let mimeType: String

        /* MARK: Init */

        init(
            _ data: Data,
            fileName: String,
            mimeType: String
        ) {
            self.data = data
            self.fileName = fileName
            self.mimeType = mimeType
        }
    }

    // MARK: - Dependencies

    @Dependency(\.build) private var build: Build
    @Dependency(\.coreKit.ui) private var coreUI: CoreKit.UI
    @Dependency(\.fileManager) private var fileManager: FileManager

    // MARK: - Properties

    static let shared = MailComposer()

    private var onComposeFinished: ((Result<MFMailComposeResult, Error>) -> Void)?

    // MARK: - Computed Properties

    var canSendMail: Bool { MFMailComposeViewController.canSendMail() }

    // MARK: - Init

    private init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Compose

    @MainActor
    func compose(
        subject: String,
        body: (string: String, isHTML: Bool)?,
        recipients: [String],
        attachments: [AttachmentData] = []
    ) {
        let composeController = MFMailComposeViewController()
        composeController.mailComposeDelegate = self

        if let body {
            composeController.setMessageBody(body.string, isHTML: body.isHTML)
        }

        composeController.setSubject(subject)
        composeController.setToRecipients(recipients)

        for attachment in attachments {
            composeController.addAttachmentData(
                attachment.data,
                mimeType: attachment.mimeType,
                fileName: attachment.fileName
            )
        }

        if !UIApplication.isFullyV26Compatible {
            StatusBar.overrideStyle(.lightContent)
        }

        coreUI.present(composeController)
    }

    // MARK: - On Compose Finished

    func onComposeFinished(perform: @escaping (Result<MFMailComposeResult, Error>) -> Void) {
        onComposeFinished = perform
    }

    // MARK: - MFMailComposeViewControllerDelegate Conformance

    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true) {
            StatusBar.restoreStyle()
            guard let error else {
                self.onComposeFinished?(.success(result))
                return
            }

            self.onComposeFinished?(.failure(error))
        }
    }
}
