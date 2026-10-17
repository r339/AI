import Foundation
import SwiftData

enum RoutineScheduler {
    /// Creates the day's task for every active routine that applies and doesn't have one yet.
    static func materialize(for day: Date, in context: ModelContext) {
        let start = day.startOfDay
        let end = start.adding(days: 1)

        let routines = (try? context.fetch(FetchDescriptor<Routine>(
            predicate: #Predicate { $0.isActive == true }
        ))) ?? []
        guard !routines.isEmpty else { return }

        let existing = (try? context.fetch(FetchDescriptor<TaskItem>(
            predicate: #Predicate { $0.day >= start && $0.day < end && $0.routineID != nil }
        ))) ?? []
        let existingRoutineIDs = Set(existing.compactMap(\.routineID))

        for routine in routines where routine.applies(on: start) && !existingRoutineIDs.contains(routine.id) {
            let task = TaskItem(
                title: routine.title,
                notes: routine.notes,
                day: start,
                dueTime: routine.timeOfDay,
                priority: Priority(rawValue: routine.priorityRaw) ?? .off,
                reminderEnabled: routine.reminderEnabled,
                routineID: routine.id
            )
            context.insert(task)
            NotificationManager.shared.sync(task)
        }
    }

    static func routine(id: UUID, in context: ModelContext) -> Routine? {
        var descriptor = FetchDescriptor<Routine>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    /// Unlinks a task from its routine and remembers that the routine shouldn't refill that day.
    /// Call before deleting a routine task or moving it to another day.
    static func detach(_ task: TaskItem, in context: ModelContext) {
        guard let routineID = task.routineID else { return }
        if let routine = routine(id: routineID, in: context), !routine.skippedDays.contains(task.day) {
            routine.skippedDays.append(task.day)
        }
        task.routineID = nil
    }

    /// Stops a routine and removes its unfinished tasks after `day`.
    static func stop(_ routine: Routine, after day: Date, in context: ModelContext) {
        routine.isActive = false
        let routineID: UUID? = routine.id
        let cutoff = day.startOfDay
        let future = (try? context.fetch(FetchDescriptor<TaskItem>(
            predicate: #Predicate { $0.routineID == routineID && $0.day > cutoff && $0.isCompleted == false }
        ))) ?? []
        for task in future {
            NotificationManager.shared.cancel(task)
            context.delete(task)
        }
    }
}
