import SwiftUI

struct ProgressCard: View {
    let done: Int
    let total: Int

    private var fraction: Double {
        total == 0 ? 0 : Double(done) / Double(total)
    }

    private var message: String {
        if total == 0 { return "A fresh day" }
        if done == total { return "All done. Nice work." }
        let left = total - done
        return "\(left) task\(left == 1 ? "" : "s") to go"
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color(.tertiarySystemFill), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int((fraction * 100).rounded()))%")
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .frame(width: 54, height: 54)
            .animation(.snappy, value: fraction)

            VStack(alignment: .leading, spacing: 2) {
                Text(message)
                    .font(.headline)
                Text("\(done) of \(total) done")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}
