//
//  TimestampDateFormatterDependency.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation

/// The dependency key that provides a ``DateFormatter`` instance.
public enum TimestampDateFormatterDependency: DependencyKey {
    public static func resolve(_: DependencyValues) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.timeZone = .init(identifier: "UTC")
        return formatter
    }
}

public extension DependencyValues {
    /// The shared ``DateFormatter`` instance.
    var timestampDateFormatter: DateFormatter {
        get { self[TimestampDateFormatterDependency.self] }
        set { self[TimestampDateFormatterDependency.self] = newValue }
    }
}
