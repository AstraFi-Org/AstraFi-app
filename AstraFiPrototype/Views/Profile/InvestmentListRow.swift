import SwiftUI

struct InvestmentListRow: View {
    let investment: AstraInvestment
    let editAction: () -> Void
    @Environment(AppStateManager.self) var appState

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(investment.investmentName).font(.headline)
                    Spacer()
                    Text(investment.investmentType.rawValue)
                        .font(.caption).padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1)).cornerRadius(4)
                }
                HStack {
                    Label(investment.mode == .sip ? "SIP" : "Lumpsum", systemImage: investment.mode == .sip ? "repeat.circle" : "arrow.down.circle")
                        .font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text(investment.mode == .sip ? "₹\(Int(investment.investmentAmount))/mo" : investment.investmentAmount.toCurrency())
                        .font(.subheadline).fontWeight(.bold)
                }
                if let goalID = investment.associatedGoalID,
                   let goalName = appState.currentProfile?.goals.first(where: { $0.id == goalID })?.goalName {
                    Label("Goal: \(goalName)", systemImage: "target")
                        .font(.caption2).foregroundColor(.blue)
                }
                Text("Since \(investment.startDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2).foregroundColor(.secondary)
            }
            Button(action: editAction) {
                Image(systemName: "pencil.circle.fill").font(.title3).foregroundColor(.blue)
            }
            .buttonStyle(.plain).padding(.leading, 8)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        InvestmentListRow(
            investment: AstraInvestment(
                investmentType: .mutualFund,
                subtype: .equityFund,
                investmentName: "Axis Bluechip Fund",
                investmentAmount: 5000,
                startDate: Date().addingTimeInterval(-86400 * 30),
                associatedGoalID: nil,
                mode: .sip
            ),
            editAction: {}
        )
        .environment(AppStateManager.withSampleData())
    }
}
