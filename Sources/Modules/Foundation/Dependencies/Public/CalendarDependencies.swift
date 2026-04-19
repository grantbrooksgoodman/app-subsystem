//
//  CalendarDependencies.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// The dependency key that provides a ``Calendar`` instance for the current calendar.
public enum CurrentCalendarDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> Calendar {
        .current
    }
}

/// The dependency key that provides a ``Calendar`` instance for the system localized calendar.
public enum SystemLocalizedCalendarDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> Calendar {
        var calendar: Calendar = .current
        calendar.locale = .init(languageCode: .init(RuntimeStorage.languageCode))
        return calendar
    }
}

public extension DependencyValues {
    /// The shared current ``Calendar`` instance.
    var currentCalendar: Calendar {
        get { self[CurrentCalendarDependency.self] }
        set { self[CurrentCalendarDependency.self] = newValue }
    }

    /// The shared localized ``Calendar`` instance.
    var systemLocalizedCalendar: Calendar {
        get { self[SystemLocalizedCalendarDependency.self] }
        set { self[SystemLocalizedCalendarDependency.self] = newValue }
    }
}
