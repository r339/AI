# Daily Tasks (iOS)

A SwiftUI + SwiftData app for planning and checking off your day's tasks. Requires iOS 17 and Xcode 16 or later.

## Features

- **Day view** with a swipeable week strip to jump between days, plus a "Today" button.
- **Progress ring** showing how much of the day is done.
- **Quick add**: type in the "Add a task" row and press return. Use **+** for the full editor.
- **Task details**: notes, date, optional time, a reminder notification, and priority (None/Low/Medium/High).
- **Repeating tasks**: every day or on chosen weekdays. Each day gets its own copy, so checking one off doesn't affect other days.
- **Overdue**: unfinished one-off tasks from earlier days show on Today, with "Move all to today".
- **Gestures**: swipe right to complete; swipe left to delete or push to tomorrow; long-press for more; tap to edit.
- Data stays on the device (SwiftData). No account, no network.

## Run it

1. On a Mac, open `DailyTasks.xcodeproj` in Xcode 16+.
2. Select the **DailyTasks** target → **Signing & Capabilities** → choose your Team (a free Apple ID works) and change the bundle identifier from `com.example.DailyTasks` to something unique.
3. Pick an iPhone simulator, or your iPhone plugged in (enable Developer Mode on the phone), and press **Run**.

With a free Apple ID, apps installed on a real phone expire after 7 days and need re-running from Xcode. A paid developer account ($99/yr) removes that limit and allows TestFlight.

## Known limitations

- Repeating tasks are created when the app opens (today plus the next two days), or when you view a day. A routine's reminder only fires if its day has been created, so open the app now and then.
- Editing one day of a repeating task changes only that day, not the whole series. "Stop repeating" ends the series and removes its unfinished future copies.

## Layout

```
Design/AppIcon.svg           Source for the app icon (re-export to 1024×1024 PNG, no transparency)
DailyTasks/
  DailyTasksApp.swift        App entry, notification delegate
  Models/                    TaskItem, Routine, Priority
  Services/                  NotificationManager, RoutineScheduler
  Support/                   Date helpers
  Views/                     ContentView, WeekStrip, DayTaskList, TaskRow, ProgressCard, TaskEditorView
```

## Web preview

`docs/` holds a browser version of the app for trying it on any phone without installing anything. It mirrors the Swift app's rules but is separate code, and its data stays in that browser. To host it, turn on GitHub Pages: **Settings → Pages → Deploy from a branch → `main` / `docs`**. It will be at `https://r339.github.io/AI/`. On iPhone, open that in Safari and use **Share → Add to Home Screen** to get a full-screen icon.
