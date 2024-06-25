//
//  NotificationCenter+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension NotificationCenter {
    func addObserver(
        _ observer: AnyObject,
        name: NSNotification.Name,
        object: Any? = nil,
        removeAfterFirstPost: Bool = false,
        selector: @escaping (Notification) -> Void
    ) {
        let wrapper = NotificationHandler(
            observer,
            name: name,
            object: object,
            removeAfterFirstPost: removeAfterFirstPost,
            effect: selector
        )

        addObserver(
            wrapper,
            selector: #selector(NotificationHandler.handleNotification(_:)),
            name: name,
            object: object
        )

        // Store the wrapper to keep it alive
        objc_setAssociatedObject(
            observer,
            "\(name.rawValue)-notificationHandler",
            wrapper,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
}

private final class NotificationHandler {
    // MARK: - Dependencies

    @Dependency(\.notificationCenter) private var notificationCenter: NotificationCenter

    // MARK: - Properties

    private let effect: (Notification) -> Void
    private let name: NSNotification.Name
    private let object: Any?
    private let removeAfterFirstPost: Bool

    private weak var observer: AnyObject?

    // MARK: - Init

    init(
        _ observer: AnyObject,
        name: NSNotification.Name,
        object: Any?,
        removeAfterFirstPost: Bool,
        effect: @escaping (Notification) -> Void
    ) {
        self.observer = observer
        self.name = name
        self.object = object
        self.removeAfterFirstPost = removeAfterFirstPost
        self.effect = effect
    }

    // MARK: - Handle Notification

    @objc
    func handleNotification(_ notification: Notification) {
        effect(notification)

        guard let observer,
              removeAfterFirstPost else { return }

        notificationCenter.removeObserver(
            self,
            name: name,
            object: object
        )

        objc_setAssociatedObject(
            observer,
            "\(name.rawValue)-notificationHandler",
            nil,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
}
