import SwiftUI

struct FullInvestmentListView: View {
    @Environment(AppStateManager.self) var appState
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    private var investments: [AstraInvestment] {
        (appState.currentProfile?.investments ?? [])
            .sorted(by: { $0.createdAt > $1.createdAt })
    }
    
    private var df: DateFormatter {
        let f = DateFormatter(); f.dateStyle = .medium; return f
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if investments.isEmpty {
                        Text("No investments recorded yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 40)
                    } else {
                        ForEach(investments) { inv in
                            NavigationLink(destination: InvestmentDetailView(investmentID: inv.id)) {
                                InvestmentRowView(
                                    name: inv.investmentName,
                                    category: inv.investmentType.rawValue,
                                    risk: riskLabel(for: inv),
                                    amount: inv.currentValue.toCurrency(),
                                    gain: (inv.currentGain >= 0 ? "+" : "") + inv.currentGain.toCurrency(),
                                    startDate: df.string(from: inv.startDate),
                                    goal: goalName(for: inv)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("All Investments")
            .navigationBarTitleDisplayMode(.inline)
            .background(AppTheme.appBackground(for: colorScheme))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").fontWeight(.semibold)
                    }
                }
            }
        }
    }
    
    private func riskLabel(for inv: AstraInvestment) -> String {
        switch inv.investmentType {
        case .stocks: return "High Risk"
        case .mutualFund: return "Moderate Risk"
        case .goldETF: return "Low Risk"
        case .physicalGold: return "Low Risk"
        case .deposits: return "Low Risk"
        case .cryptocurrency: return "Very High Risk"
        case .realEstate: return "Low Risk"
        case .bonds: return "Low Risk"
        case .ppf: return "Low Risk"
        case .nps: return "Moderate Risk"
        case .other: return "Moderate Risk"
        }
    }

    private func goalName(for inv: AstraInvestment) -> String {
        guard let gid = inv.associatedGoalID,
              let goal = appState.currentProfile?.goals.first(where: { $0.id == gid })
        else { return "General" }
        return goal.goalName
    }
}
#Preview {
    let sampleState = AppStateManager.withSampleData()

    FullInvestmentListView()
        .environment(sampleState)
}
