import Foundation
import SwiftData

@Model
final class TaskItem {
    var id: UUID
    var title: String
    var notes: String
    /// Start of the day this task is planned for.
    var day: Date
    /// Only the hour and minute are used; combined with `day` via `scheduledDate`.
    var dueTime: Date?
    var priorityRaw: Int
    var isCompleted: Bool
    var completedAt: Date?
    var createdAt: Date
    var reminderEnabled: Bool
    /// Set when this task was generated from a repeating `Routine`.
    var routineID: UUID?

    init(
        title: String,
        notes: String = "",
        day: Date,
        dueTime: Date? = nil,
        priority: Priority = .off,
        reminderEnabled: Bool = false,
        routineID: UUID? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.day = day.startOfDay
        self.dueTime = dueTime
        self.priorityRaw = priority.rawValue
        self.isCompleted = false
        self.completedAt = nil
        self.createdAt = .now
        self.reminderEnabled = reminderEnabled
        self.routineID = routineID
    }

    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .off }
        set { priorityRaw = newValue.rawValue }
    }

    /// The task's day combined with its time, if it has one.
    var scheduledDate: Date? {
        guard let dueTime else { return nil }
        let calendar = Calendar.current
        let time = calendar.dateComponents([.hour, .minute], from: dueTime)
        return calendar.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0, second: 0, of: day)
    }

    func setCompleted(_ completed: Bool) {
        isCompleted = completed
        completedAt = completed ? .now : nil
    }

    /// Timed tasks first (earliest first), then by priority, then oldest first.
    static func displayOrder(_ a: TaskItem, _ b: TaskItem) -> Bool {
        switch (a.scheduledDate, b.scheduledDate) {
        case let (x?, y?) where x != y: return x < y
        case (.some, .none): return true
        case (.none, .some): return false
        default: break
        }
        if a.priorityRaw != b.priorityRaw { return a.priorityRaw > b.priorityRaw }
        return a.createdAt < b.createdAt
    }
}
