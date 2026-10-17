import Foundation
import SwiftData

/// A repeating task. Each day it applies to gets its own `TaskItem`,
/// so completion is tracked per day.
@Model
final class Routine {
    var id: UUID
    var title: String
    var notes: String
    var priorityRaw: Int
    var timeOfDay: Date?
    var reminderEnabled: Bool
    var startDay: Date
    /// `Calendar` weekday numbers (1 = Sunday). Empty means every day.
    var weekdays: [Int]
    /// Days whose generated task was deleted or moved, so it isn't recreated.
    var skippedDays: [Date]
    var isActive: Bool

    init(
        title: String,
        notes: String,
        priority: Priority,
        timeOfDay: Date?,
        reminderEnabled: Bool,
        startDay: Date,
        weekdays: [Int]
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.priorityRaw = priority.rawValue
        self.timeOfDay = timeOfDay
        self.reminderEnabled = reminderEnabled
        self.startDay = startDay.startOfDay
        self.weekdays = weekdays
        self.skippedDays = []
        self.isActive = true
    }

    func applies(on day: Date) -> Bool {
        let day = day.startOfDay
        guard isActive, day >= startDay, !skippedDays.contains(day) else { return false }
        return weekdays.isEmpty || weekdays.contains(Calendar.current.component(.weekday, from: day))
    }
}
