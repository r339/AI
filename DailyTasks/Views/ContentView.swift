import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedDay = Date.now.startOfDay
    @State private var today = Date.now.startOfDay
    @State private var showingNewTask = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                WeekStrip(selectedDay: $selectedDay)
                DayTaskList(day: selectedDay)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !selectedDay.isToday {
                        Button("Today") {
                            withAnimation(.snappy) { selectedDay = .now.startOfDay }
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .accessibilityLabel("New task")
                }
            }
            .sheet(isPresented: $showingNewTask) {
                TaskEditorView(mode: .new(day: selectedDay))
            }
        }
        .task(id: selectedDay) {
            RoutineScheduler.materialize(for: selectedDay, in: context)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            let now = Date.now.startOfDay
            // If the app was left open on "Today" overnight, follow the new day.
            if now != today {
                if selectedDay == today { selectedDay = now }
                today = now
            }
            // Fill in routines ahead of time so their reminders get scheduled.
            for offset in 0...2 {
                RoutineScheduler.materialize(for: now.adding(days: offset), in: context)
            }
        }
    }

    private var title: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDay) { return "Today" }
        if calendar.isDateInTomorrow(selectedDay) { return "Tomorrow" }
        if calendar.isDateInYesterday(selectedDay) { return "Yesterday" }
        return selectedDay.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TaskItem.self, Routine.self], inMemory: true)
}
