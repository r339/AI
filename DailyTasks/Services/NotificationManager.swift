import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Schedules, reschedules or removes the reminder so it matches the task's current state.
    func sync(_ task: TaskItem) {
        let identifier = task.id.uuidString
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard task.reminderEnabled, !task.isCompleted,
              let fireDate = task.scheduledDate, fireDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = task.title
        content.body = task.notes.isEmpty ? "Time for this task." : task.notes
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    func cancel(_ task: TaskItem) {
        center.removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }
}
