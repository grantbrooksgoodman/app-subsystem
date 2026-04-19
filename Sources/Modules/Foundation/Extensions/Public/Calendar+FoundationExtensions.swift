//
//  Calendar+FoundationExtensions.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

public extension Calendar {
    // MARK: - Types

    /// A calendar date component that can be localized into a
    /// human-readable string.
    enum LocalizableComponent: CaseIterable {
        /* MARK: Cases */

        case day
        case hour
        case minute
        case month
        case second
        case week
        case year

        /* MARK: Properties */

        /// The equivalent `Calendar.Component`.
        var asComponent: Component {
            switch self {
            case .day: .day
            case .hour: .hour
            case .minute: .minute
            case .month: .month
            case .second: .second
            case .week: .weekOfMonth
            case .year: .year
            }
        }

        /// The equivalent `NSCalendar.Unit`.
        var asNSCalendarUnit: NSCalendar.Unit {
            switch self {
            case .day: .day
            case .hour: .hour
            case .minute: .minute
            case .month: .month
            case .second: .second
            case .week: .weekOfMonth
            case .year: .year
            }
        }
    }

    // MARK: - Methods

    /// Returns a localized name for the given date component, such
    /// as "hours" or "minutes".
    func localizedString(
        for component: LocalizableComponent,
        plural: Bool = false,
        style: DateComponentsFormatter.UnitsStyle = .full
    ) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.calendar = self
        formatter.allowedUnits = [component.asNSCalendarUnit]
        formatter.unitsStyle = style

        let currentDate = Date.now
        guard let date = date(
            byAdding: .init(component),
            value: plural ? 2 : 1,
            to: currentDate
        ) else { return nil }
        let interval = date.timeIntervalSince(currentDate)
        guard let string = formatter.string(from: interval) else { return nil }
        return string.removingOccurrences(of: [plural ? "2" : "1"]).trimmingWhitespace
    }
}

private extension Calendar.Component {
    init(_ component: Calendar.LocalizableComponent) {
        switch component {
        case .day: self = .day
        case .hour: self = .hour
        case .minute: self = .minute
        case .month: self = .month
        case .second: self = .second
        case .week: self = .weekOfMonth
        case .year: self = .year
        }
    }
}
