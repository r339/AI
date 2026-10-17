import SwiftUI
import SwiftData

struct DayTaskList: View {
    let day: Date

    @Environment(\.modelContext) private var context
    @Query private var tasks: [TaskItem]
    @Query private var unfinishedEarlier: [TaskItem]

    @State private var editingTask: TaskItem?
    @State private var quickTitle = ""
    @FocusState private var quickAddFocused: Bool

    init(day: Date) {
        self.day = day
        let start = day.startOfDay
        let end = start.adding(days: 1)
        _tasks = Query(filter: #Predicate<TaskItem> { $0.day >= start && $0.day < end })

        let today = Date.now.startOfDay
        _unfinishedEarlier = Query(
            filter: #Predicate<TaskItem> { $0.isCompleted == false && $0.day < today },
            sort: \TaskItem.day
        )
    }

    private var pending: [TaskItem] {
        tasks.filter { !$0.isCompleted }.sorted(by: TaskItem.displayOrder)
    }

    private var done: [TaskItem] {
        tasks.filter(\.isCompleted).sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    /// Missed one-off tasks from earlier days. Missed routine days aren't carried over.
    private var overdue: [TaskItem] {
        guard day.isToday else { return [] }
        return unfinishedEarlier.filter { $0.routineID == nil }
    }

    var body: some View {
        List {
            Section {
                ProgressCard(done: done.count, total: tasks.count)
            }

            if !overdue.isEmpty {
                Section {
                    ForEach(overdue) { row(for: $0, showsDay: true) }
                } header: {
                    HStack {
                        Text("Overdue")
                        Spacer()
                        Button("Move all to today") { moveOverdueToToday() }
                            .font(.caption.weight(.semibold))
                            .textCase(nil)
                    }
                }
            }

            Section("To do") {
                if pending.isEmpty && done.isEmpty {
                    Text("Nothing planned. Add a task below or tap +.")
                        .foregroundStyle(.secondary)
                }
                ForEach(pending) { row(for: $0) }
                quickAddRow
            }

            if !done.isEmpty {
                Section("Done") {
                    ForEach(done) { row(for: $0) }
                }
            }
        }
        .listStyle(.insetGrouped)
        .sheet(item: $editingTask) { task in
            TaskEditorView(mode: .edit(task))
        }
    }

    private var quickAddRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus")
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)
            TextField("Add a task", text: $quickTitle)
                .focused($quickAddFocused)
                .submitLabel(.done)
                .onSubmit(addQuickTask)
        }
    }

    private func row(for task: TaskItem, showsDay: Bool = false) -> some View {
        TaskRow(task: task, showsDay: showsDay) { toggle(task) }
            .contentShape(Rectangle())
            .onTapGesture { editingTask = task }
            .swipeActions(edge: .leading) {
                Button { toggle(task) } label: {
                    Label(task.isCompleted ? "Undo" : "Done",
                          systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
                }
                .tint(.green)
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) { delete(task) } label: {
                    Label("Delete", systemImage: "trash")
                }
                Button { move(task, to: task.day.adding(days: 1)) } label: {
                    Label("Tomorrow", systemImage: "arrow.right.circle")
                }
                .tint(.indigo)
            }
            .contextMenu {
                Button { toggle(task) } label: {
                    Label(task.isCompleted ? "Mark as not done" : "Mark as done", systemImage: "checkmark.circle")
                }
                if !task.day.isToday {
                    Button { move(task, to: .now.startOfDay) } label: {
                        Label("Move to today", systemImage: "sun.max")
                    }
                }
                Button { move(task, to: task.day.adding(days: 1)) } label: {
                    Label("Move to next day", systemImage: "arrow.right.circle")
                }
                Button(role: .destructive) { delete(task) } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
    }

    private func addQuickTask() {
        let title = quickTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        withAnimation {
            context.insert(TaskItem(title: title, day: day))
        }
        quickTitle = ""
        quickAddFocused = true
    }

    private func toggle(_ task: TaskItem) {
        withAnimation(.snappy) { task.setCompleted(!task.isCompleted) }
        NotificationManager.shared.sync(task)
    }

    private func move(_ task: TaskItem, to newDay: Date) {
        withAnimation {
            RoutineScheduler.detach(task, in: context)
            task.day = newDay.startOfDay
        }
        NotificationManager.shared.sync(task)
    }

    private func delete(_ task: TaskItem) {
        NotificationManager.shared.cancel(task)
        withAnimation {
            RoutineScheduler.detach(task, in: context)
            context.delete(task)
        }
    }

    private func moveOverdueToToday() {
        let today = Date.now.startOfDay
        let moving = overdue
        withAnimation {
            for task in moving { task.day = today }
        }
        for task in moving { NotificationManager.shared.sync(task) }
    }
}
