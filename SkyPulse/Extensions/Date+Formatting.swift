import Foundation

/// Удобные методы форматирования дат для UI.
extension Date {

    /// "14:30"
    var displayTime: String {
        DateFormatters.displayTime.string(from: self)
    }

    /// "Feb 10, 2026"
    var displayDate: String {
        DateFormatters.displayDate.string(from: self)
    }

    /// "Feb 10, 2026 at 14:30"
    var displayFull: String {
        DateFormatters.displayFull.string(from: self)
    }

    /// Относительное описание: "5 min ago", "in 2 hours", "just now"
    var relativeDescription: String {
        let interval = timeIntervalSinceNow
        let absInterval = abs(interval)

        if absInterval < 60 {
            return "just now"
        } else if absInterval < 3600 {
            let minutes = Int(absInterval / 60)
            return interval > 0
                ? "in \(minutes) min"
                : "\(minutes) min ago"
        } else if absInterval < 86400 {
            let hours = Int(absInterval / 3600)
            return interval > 0
                ? "in \(hours)h"
                : "\(hours)h ago"
        } else {
            return displayDate
        }
    }
}
