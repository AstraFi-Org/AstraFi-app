import SwiftUI

struct TrackerInvestmentsSection: View {
    let investments: [Investment]
    @Environment(AppStateManager.self) var appState

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Your Investments")
                    .font(.system(size: 22, weight: .bold))
                Spacer()
                NavigationLink(destination: InvestmentOverviewView()) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.accentColor)
                }
            }
            if investments.isEmpty {
                TrackerEmptyState(icon: "chart.pie.fill",
                                  message: "No investments recorded yet. Complete your assessment to get started.")
            } else {
                VStack(spacing: 12) {
                    ForEach(investments) { investment in
                        NavigationLink(destination: investmentDestination(for: investment)) {
                            InvestmentCard(investment: investment)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func investmentDestination(for investment: Investment) -> some View {
        if let matchingInvestment = appState.currentProfile?.investments.first(where: { $0.investmentName == investment.name }) {
            InvestmentDetailView(investmentID: matchingInvestment.id)
        } else {

            Text("Investment not found")
        }
    }
}

struct InvestmentCard: View {
    let investment: Investment
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(investment.name)
                        .font(.system(size: 17, weight: .semibold))
                    HStack(spacing: 8) {
                        Text(investment.category)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Text("•").foregroundColor(.secondary)
                        Text(investment.risk)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)

                        if investment.schemeCode != nil {
                            HStack(spacing: 4) {
                                Text("•").foregroundColor(.secondary)
                                Image(systemName: "broadcast.tower")
                                    .font(.system(size: 10))
                                    .foregroundColor(.green)
                                Text("Live")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Double(investment.amount).toCurrency())
                        .font(.system(size: 20, weight: .bold))
                    if let nav = investment.lastNAV {
                        Text("NAV: ₹\(String(format: "%.2f", nav))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    } else {
                        Text(investment.returns)
                            .font(.system(size: 13))
                            .foregroundColor(investment.returns.hasPrefix("+") ? .green : .red)
                    }
                }
            }
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Started on")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Text(investment.startDate)
                        .font(.system(size: 15, weight: .medium))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Associated goal")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Text(investment.associatedGoal)
                        .font(.system(size: 15, weight: .medium))
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: AppTheme.adaptiveShadow, radius: 4, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        TrackerInvestmentsSection(investments: [
            Investment(name: "Axis Bluechip Fund", category: "Mutual Fund", risk: "Moderate", amount: 250000, returns: "+12.5%", startDate: "12 Jan 2024", associatedGoal: "Retirement"),
            Investment(name: "HDFC Top 100", category: "Mutual Fund", risk: "Moderate", amount: 150000, returns: "+8.2%", startDate: "05 Feb 2024", associatedGoal: "Child Education")
        ])
        .environment(AppStateManager())
        .padding()
    }
}
