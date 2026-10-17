import SwiftUI
import SwiftData

struct TaskEditorView: View {
    enum Mode {
        case new(day: Date)
        case edit(TaskItem)
    }

    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var notes: String
    @State private var day: Date
    @State private var hasTime: Bool
    @State private var time: Date
    @State private var reminder: Bool
    @State private var priority: Priority
    @State private var repeats = false
    @State private var weekdays: Set<Int> = []
    @State private var confirmingDelete = false
    @FocusState private var titleFocused: Bool

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .new(let day):
            _title = State(initialValue: "")
            _notes = State(initialValue: "")
            _day = State(initialValue: day)
            _hasTime = State(initialValue: false)
            _time = State(initialValue: Self.nextWholeHour())
            _reminder = State(initialValue: false)
            _priority = State(initialValue: .off)
        case .edit(let task):
            _title = State(initialValue: task.title)
            _notes = State(initialValue: task.notes)
            _day = State(initialValue: task.day)
            _hasTime = State(initialValue: task.dueTime != nil)
            _time = State(initialValue: task.dueTime ?? Self.nextWholeHour())
            _reminder = State(initialValue: task.reminderEnabled)
            _priority = State(initialValue: task.priority)
        }
    }

    private var isNew: Bool {
        if case .new = mode { return true }
        return false
    }

    private var editingTask: TaskItem? {
        if case .edit(let task) = mode { return task }
        return nil
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What needs doing?", text: $title)
                        .focused($titleFocused)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...6)
                }

                Section {
                    DatePicker("Date", selection: $day, displayedComponents: .date)
                    Toggle("Time", isOn: $hasTime.animation())
                    if hasTime {
                        DatePicker("At", selection: $time, displayedComponents: .hourAndMinute)
                        Toggle("Remind me", isOn: $reminder)
                    }
                }

                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if isNew {
                    Section {
                        Toggle("Repeat", isOn: $repeats.animation())
                        if repeats {
                            WeekdayPicker(selection: $weekdays)
                        }
                    } footer: {
                        if repeats {
                            Text(weekdays.isEmpty
                                 ? "Repeats every day. Pick days to limit it."
                                 : "Repeats on the selected days.")
                        }
                    }
                } else if let task = editingTask, let routineID = task.routineID,
                          let routine = RoutineScheduler.routine(id: routineID, in: context), routine.isActive {
                    Section {
                        Button("Stop repeating") {
                            RoutineScheduler.stop(routine, after: task.day, in: context)
                            dismiss()
                        }
                    } footer: {
                        Text("This task repeats. Changes here apply to this day only.")
                    }
                }

                if editingTask != nil {
                    Section {
                        Button("Delete task", role: .destructive) { confirmingDelete = true }
                    }
                }
            }
            .navigationTitle(isNew ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? "Add" : "Save", action: save)
                        .disabled(trimmedTitle.isEmpty)
                }
            }
            .confirmationDialog("Delete this task?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive, action: delete)
            }
            .onChange(of: reminder) { _, isOn in
                if isOn { Task { await NotificationManager.shared.requestAuthorization() } }
            }
            .onAppear {
                if isNew { titleFocused = true }
            }
        }
    }

    private func save() {
        let normalizedDay = day.startOfDay
        let dueTime = hasTime ? time : nil
        let wantsReminder = hasTime && reminder

        switch mode {
        case .new:
            if repeats {
                let routine = Routine(
                    title: trimmedTitle,
                    notes: notes,
                    priority: priority,
                    timeOfDay: dueTime,
                    reminderEnabled: wantsReminder,
                    startDay: normalizedDay,
                    weekdays: weekdays.sorted()
                )
                context.insert(routine)
                RoutineScheduler.materialize(for: normalizedDay, in: context)
            } else {
                let task = TaskItem(
                    title: trimmedTitle,
                    notes: notes,
                    day: normalizedDay,
                    dueTime: dueTime,
                    priority: priority,
                    reminderEnabled: wantsReminder
                )
                context.insert(task)
                NotificationManager.shared.sync(task)
            }

        case .edit(let task):
            if task.day != normalizedDay {
                RoutineScheduler.detach(task, in: context)
            }
            task.title = trimmedTitle
            task.notes = notes
            task.day = normalizedDay
            task.dueTime = dueTime
            task.reminderEnabled = wantsReminder
            task.priority = priority
            NotificationManager.shared.sync(task)
        }
        dismiss()
    }

    private func delete() {
        guard let task = editingTask else { return }
        NotificationManager.shared.cancel(task)
        RoutineScheduler.detach(task, in: context)
        context.delete(task)
        dismiss()
    }

    private static func nextWholeHour() -> Date {
        let calendar = Calendar.current
        let now = Date.now
        let hour = calendar.component(.hour, from: now)
        return calendar.date(bySettingHour: min(hour + 1, 23), minute: 0, second: 0, of: now) ?? now
    }
}

private struct WeekdayPicker: View {
    @Binding var selection: Set<Int>

    /// Weekday numbers ordered by the user's first day of the week.
    private var orderedWeekdays: [Int] {
        let first = Calendar.current.firstWeekday
        return (0..<7).map { (first - 1 + $0) % 7 + 1 }
    }

    var body: some View {
        HStack {
            ForEach(orderedWeekdays, id: \.self) { weekday in
                let isOn = selection.contains(weekday)
                Button {
                    if isOn { selection.remove(weekday) } else { selection.insert(weekday) }
                } label: {
                    Text(Calendar.current.veryShortWeekdaySymbols[weekday - 1])
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 34, height: 34)
                        .background(isOn ? Color.accentColor : Color(.tertiarySystemFill), in: Circle())
                        .foregroundStyle(isOn ? Color.white : Color.primary)
                }
                .buttonStyle(.borderless)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(Calendar.current.weekdaySymbols[weekday - 1])
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }
}
