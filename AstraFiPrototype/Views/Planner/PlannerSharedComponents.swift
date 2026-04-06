import SwiftUI
import Foundation

struct TableHeaderCell: View {
    let text: String
    let alignment: Alignment
    var flex: CGFloat = 1

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity * flex, alignment: alignment)
    }
}

func riskText(_ level: AstraRiskLevel) -> String {
    switch level {
    case .low: return "Low"
    case .mid: return "Medium"
    case .high: return "High"
    }
}

func riskColor(_ level: AstraRiskLevel) -> Color {
    switch level {
    case .low: return .green
    case .mid: return .orange
    case .high: return .red
    }
}

