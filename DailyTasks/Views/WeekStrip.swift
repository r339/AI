import SwiftUI

struct WeekStrip: View {
    @Binding var selectedDay: Date

    private var days: [Date] {
        let start = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDay)?.start ?? selectedDay
        return (0..<7).map { start.adding(days: $0) }
    }

    var body: some View {
        HStack(spacing: 2) {
            Button { shift(by: -7) } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 28, height: 44)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Previous week")

            ForEach(days, id: \.self) { date in
                DayCell(
                    date: date,
                    isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDay),
                    isToday: date.isToday
                )
                .onTapGesture {
                    withAnimation(.snappy) { selectedDay = date }
                }
            }

            Button { shift(by: 7) } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 28, height: 44)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Next week")
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 30).onEnded { value in
                if value.translation.width < -50 { shift(by: 7) }
                if value.translation.width > 50 { shift(by: -7) }
            }
        )
    }

    private func shift(by days: Int) {
        withAnimation(.snappy) { selectedDay = selectedDay.adding(days: days) }
    }
}

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(date.formatted(.dateTime.weekday(.narrow)))
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            Text(date.formatted(.dateTime.day()))
                .font(.callout.weight(.semibold))
                .frame(width: 36, height: 36)
                .background(isSelected ? Color.accentColor : Color.clear, in: Circle())
                .foregroundStyle(isSelected ? Color.white : (isToday ? Color.accentColor : Color.primary))
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
