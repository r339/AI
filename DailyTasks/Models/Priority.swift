import SwiftUI

enum Priority: Int, CaseIterable, Identifiable {
    case off = 0, low, medium, high

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .off: "None"
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }

    var color: Color {
        switch self {
        case .off: .secondary
        case .low: .blue
        case .medium: .orange
        case .high: .red
        }
    }
}
