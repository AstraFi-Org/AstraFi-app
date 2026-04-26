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


struct ScenarioHeaderRow: View {
    var body: some View {
        HStack(spacing: 8) {
            TableHeaderCell(text: "Scenario", alignment: .leading, flex: 1.0)
            TableHeaderCell(text: "Gain/Loss", alignment: .trailing, flex: 1.0)
            TableHeaderCell(text: "Final Value", alignment: .trailing, flex: 1.0)
        }
    }
}

struct ScenarioDataRow: View {
    let scenario: String
    let gainLoss: String
    let finalValue: String
    let isNegative: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(scenario).font(.caption).foregroundColor(.primary).frame(maxWidth: .infinity, alignment: .leading)
            Text(gainLoss).font(.caption).fontWeight(.semibold).foregroundColor(isNegative ? .red : .primary).frame(maxWidth: .infinity, alignment: .trailing)
            Text(finalValue).font(.caption).fontWeight(.medium).foregroundColor(.primary).frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

struct InvestmentTableRow: View {
    let type: String
    let invested: String
    let expected: String
    let risk: String
    let riskColor: Color

    var body: some View {
        HStack(spacing: 0) {
            Text(type).font(.caption).foregroundColor(.primary).frame(maxWidth: .infinity * 2.5, alignment: .leading)
            Text(invested).font(.caption).foregroundColor(.primary).frame(maxWidth: .infinity * 1.5, alignment: .trailing)
            Text(expected).font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity * 1.5, alignment: .trailing)
            Text(risk).font(.system(size: 10, weight: .bold)).foregroundColor(riskColor).frame(maxWidth: .infinity * 1.2, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
    }
}

struct RiskOptionCard: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? color.opacity(0.15) : Color.gray.opacity(0.05))
            .foregroundColor(isSelected ? color : .secondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
    }
}
