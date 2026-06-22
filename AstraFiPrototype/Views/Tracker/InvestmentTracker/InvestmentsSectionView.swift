import SwiftUI

struct TrackerInvestmentsSection: View {
    let investments: [Investment]
    @Environment(AppStateManager.self) var appState

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Investments").font(.auraHeader(size: 22))
                Spacer()
                NavigationLink(destination: InvestmentOverviewView()) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(AppTheme.auraIndigo)
                }
            }
            if investments.isEmpty {
                TrackerEmptyState(icon: "chart.pie.fill",
                                  message: "No investments recorded yet. Complete your assessment to get started.")
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(investments.prefix(3))) { investment in
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
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(investment.name).font(.auraHeader(size: 17))
                    HStack(spacing: 8) {
                        Text(investment.category).font(.auraCaption()).foregroundColor(.secondary)
                        Text("•").font(.auraCaption()).foregroundColor(.secondary)
                        Text(investment.risk).font(.auraCaption()).foregroundColor(.secondary)
                        
                        if investment.schemeCode != nil {
                            Text("LIVE").font(.auraCaption(size: 9, weight: .black)).padding(.horizontal, 6).padding(.vertical, 2).background(.green).cornerRadius(4).foregroundColor(.black)
                        }

                        if let source = investment.source {
                            Text(source.uppercased())
                                .font(.auraCaption(size: 9, weight: .black))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.auraIndigo.opacity(0.14))
                                .foregroundColor(AppTheme.auraIndigo)
                                .cornerRadius(4)
                        }
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(Double(investment.amount).toCurrency())
                        .font(.auraDigital(size: 18))
                        .foregroundColor(AppTheme.auraIndigo)
                    
                    if let nav = investment.lastNAV {
                        Text("NAV ₹\(String(format: "%.2f", nav))").font(.auraCaption(size: 11)).foregroundColor(.secondary)
                    } else {
                        Text(investment.returns).font(.auraCaption(size: 11)).foregroundColor(investment.returns.hasPrefix("+") ? .green : .red)
                    }
                }
            }
            
            Divider().background(Color.gray.opacity(0.1))
            
            HStack {
                Label(investment.startDate, systemImage: "calendar")
                    .font(.auraCaption())
                    .foregroundColor(.secondary)
                Spacer()
                Label(investment.associatedGoal, systemImage: "flag.fill")
                    .font(.auraCaption())
                    .foregroundColor(.secondary)
            }
        }
        .auraCardStyle(radius: 24)
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
