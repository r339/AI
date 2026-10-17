import SwiftUI

struct TaskRow: View {
    let task: TaskItem
    var showsDay = false
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? Color.green : task.priority.color)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 28)
            }
            .buttonStyle(.borderless)
            .sensoryFeedback(.success, trigger: task.isCompleted) { _, isCompleted in isCompleted }
            .accessibilityLabel(task.isCompleted ? "Mark as not done" : "Mark as done")

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? Color.secondary : Color.primary)

                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if hasDetails {
                    HStack(spacing: 10) {
                        if showsDay {
                            Label(task.day.formatted(.dateTime.month(.abbreviated).day()), systemImage: "calendar")
                        }
                        if let date = task.scheduledDate {
                            Label(date.formatted(date: .omitted, time: .shortened),
                                  systemImage: task.reminderEnabled ? "bell.fill" : "clock")
                        }
                        if task.routineID != nil {
                            Image(systemName: "repeat")
                                .accessibilityLabel("Repeats")
                        }
                        if task.priority != .off {
                            Label(task.priority.label, systemImage: "flag.fill")
                                .foregroundStyle(task.priority.color)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }

    private var hasDetails: Bool {
        showsDay || task.dueTime != nil || task.routineID != nil || task.priority != .off
    }
}
