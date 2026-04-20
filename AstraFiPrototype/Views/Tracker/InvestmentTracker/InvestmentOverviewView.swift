import SwiftUI
import Charts

struct YearlyData: Identifiable {
    let id = UUID()
    let year: String
    let value: Double
    let recommendedIncrease: Double
    let isCurrent: Bool
}

struct InvestmentOverviewView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppStateManager.self) var appState
    @Environment(\.dismiss) var dismiss

    private var investments: [AstraInvestment] { appState.currentProfile?.investments ?? [] }
    private var insurances: [AstraInsurance]   { appState.currentProfile?.insurances ?? [] }

    private var totalInvested: Double { investments.reduce(0) { $0 + $1.investmentAmount } }
    private var totalCurrentValue: Double { investments.reduce(0) { $0 + $1.currentValue } }
    private var totalGain: Double { totalCurrentValue - totalInvested }
    private var totalValue: Double { totalCurrentValue }

    private var df: DateFormatter {
        let f = DateFormatter(); f.dateStyle = .medium; return f
    }

    private var chartData: [YearlyData] {
        let cal = Calendar.current
        let currentYear = cal.component(.year, from: Date())

        let monthlyIncome = appState.currentProfile?.basicDetails.monthlyIncomeAfterTax ?? 0
        let monthlyExpenses = appState.currentProfile?.basicDetails.monthlyExpenses ?? 0
        let annualSavingsCapacity = max(0, (monthlyIncome - monthlyExpenses) * 12)

        let currentAnnualInvested = investments.reduce(0.0) { total, inv in
            if inv.mode == .sip {
                return total + (inv.investmentAmount * 12)
            } else {
                return total
            }
        }

        var data: [YearlyData] = []
        for offset in 0...2 {
            let year = currentYear + offset
            let isCurrent = offset == 0

            let capacity = annualSavingsCapacity * pow(1.08, Double(offset))
            let currentTrend = currentAnnualInvested * pow(1.05, Double(offset))
            let increase = max(0, capacity - currentTrend)

            data.append(YearlyData(
                year: "\(year)",
                value: capacity,
                recommendedIncrease: increase,
                isCurrent: isCurrent
            ))
        }
        return data
    }

    @State private var showingAddInvestment = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                totalValueCard
                investmentChart
                investmentsList
                insuranceSection
            }
            .padding()
        }
        .navigationTitle("Investment Overview")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").fontWeight(.semibold)
                }
                .buttonStyle(.plain)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAddInvestment = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showingAddInvestment) {
            AddInvestmentView()
        }
        .background(AppTheme.appBackground(for: colorScheme))
    }

    private var totalValueCard: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Total Value")
                        .font(.title3).fontWeight(.semibold)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(totalValue.toCurrency())
                            .font(.system(size: 36, weight: .bold))
                        HStack(spacing: 4) {
                            Image(systemName: totalGain >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption).foregroundColor(totalGain >= 0 ? .green : .red)
                            let pct = totalInvested > 0 ? abs(totalGain/totalInvested)*100 : 0
                            Text(String(format: "%.1f%%", pct))
                                .font(.title3).foregroundColor(totalGain >= 0 ? .green : .red)
                        }
                    }
                    Text(totalGain >= 0 ? "Annual profit rate" : "Annual loss rate")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Invested").font(.subheadline).foregroundColor(.secondary)
                    Text(totalInvested.toCurrency()).font(.title2).fontWeight(.bold)
                }
                .padding().frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemGroupedBackground)).cornerRadius(12)

                VStack(alignment: .leading, spacing: 8) {
                    Text(totalGain >= 0 ? "Gain" : "Loss").font(.subheadline).foregroundColor(.secondary)
                    Text(totalGain.toCurrency()).font(.title2).fontWeight(.bold).foregroundColor(totalGain >= 0 ? .green : .red)
                }
                .padding().frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemGroupedBackground)).cornerRadius(12)
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }

    private var investmentChart: some View {
        VStack(alignment: .leading, spacing: 16) {

            VStack(alignment: .leading, spacing: 4) {
                Text("Investment Recommendation").font(.system(size: 16, weight: .semibold))
                Text("Based on your savings of \(((appState.currentProfile?.basicDetails.monthlyIncomeAfterTax ?? 0) - (appState.currentProfile?.basicDetails.monthlyExpenses ?? 0)).toCurrency())/mo").font(.system(size: 11, weight: .medium)).foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)

            Chart(chartData) { dp in
                BarMark(
                    x: .value("Year", dp.year),
                    y: .value("Amount", dp.value),
                    width: 24
                )
                .foregroundStyle(
                    dp.isCurrent
                        ? LinearGradient(
                            colors: [.green,
                                     .green],
                            startPoint: .top, endPoint: .bottom)
                        : LinearGradient(
                            colors: [.blue.opacity(0.8), .blue.opacity(0.5)],
                            startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(6)
                .annotation(position: .top, spacing: 4) {
                    if dp.recommendedIncrease > 0 {
                        VStack(spacing: 2) {
                            Text("Increase")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.secondary)
                            Text(dp.recommendedIncrease.toCurrency(compact: true))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.primary)
                        }
                    }
                }

                if dp.isCurrent {
                    RuleMark(x: .value("Now", dp.year))
                        .foregroundStyle(Color.orange.opacity(0.45))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                        .annotation(position: .top, alignment: .center) {
                            Text("Now")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(4)
                                .offset(y: -40)
                        }
                }
            }
            .frame(height: 240)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { val in
                    AxisGridLine().foregroundStyle(Color.secondary.opacity(0.15))
                    AxisValueLabel {
                        if let v = val.as(Double.self) {
                            Text(v.toCurrency())
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.secondary)
                }
            }
            .padding(.horizontal, 20)

            Text("You are currently investing less than your potential saving capacity. Increasing your monthly SIPs can help you reach your goals faster.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.top, 10)
        }
        .padding(.vertical, 20)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }

    private var investmentsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Investments").font(.title2).fontWeight(.bold)
                Spacer()
                NavigationLink(destination: FullInvestmentListView()) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.accentColor)
                }
            }
            
            VStack(spacing: 12) {
                let sortedInv = investments.sorted(by: { $0.createdAt > $1.createdAt })
                let recentInv = sortedInv.prefix(3)
                
                if recentInv.isEmpty {
                    Text("No investments recorded yet")
                        .font(.subheadline).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity).padding(24)
                        .background(AppTheme.cardBackground).cornerRadius(12)
                } else {
                    ForEach(recentInv) { inv in
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
                        .transition(.asymmetric(insertion: .push(from: .top), removal: .opacity))
                    }
                }
            }
            .animation(.easeInOut, value: investments)
        }
    }

    private var insuranceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Insurance").font(.title2).fontWeight(.bold)
                Spacer()
                NavigationLink(destination: InsuranceListView()) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.accentColor)
                }
            }
            if insurances.isEmpty {
                Text("No insurance policies recorded yet")
                    .font(.subheadline).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity).padding(24)
                    .background(AppTheme.cardBackground).cornerRadius(12)
            } else {
                ForEach(insurances) { ins in
                    NavigationLink(destination: InsuranceDetailView(insurance: ins)) {
                        InsuranceCard(
                            title: ins.insuranceType.rawValue + " Insurance",
                            subtitle: ins.provider,
                            status: ins.status.rawValue,
                            claimedAmount: (ins.claims.first?.amount ?? 0).toCurrency(),
                            sumInsured: ins.sumAssured.toCurrency(),
                            renewalDate: df.string(from: ins.expiryDate ?? ins.startDate)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
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

struct InvestmentRowView: View {
    let name: String
    let category: String
    let risk: String
    let amount: String
    let gain: String
    let startDate: String
    let goal: String

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name).font(.headline).foregroundColor(.primary)
                    HStack(spacing: 8) {
                        Text(category).font(.subheadline).foregroundColor(.secondary)
                        Text("•").foregroundColor(.secondary)
                        Text(risk).font(.subheadline).foregroundColor(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(amount).font(.title3).fontWeight(.bold)
                    HStack(spacing: 2) {
                        let isPositive = !gain.contains("-")
                        Text(gain).font(.subheadline).foregroundColor(isPositive ? .green : .red)
                        Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                            .font(.caption).foregroundColor(isPositive ? .green : .red)
                    }
                }
            }
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Started on").font(.caption).foregroundColor(.secondary)
                    Text(startDate).font(.subheadline)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Associated goal").font(.caption).foregroundColor(.secondary)
                    Text(goal).font(.subheadline)
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }
}

struct InsuranceCard: View {
    let title: String
    let subtitle: String
    let status: String
    let claimedAmount: String
    var registrationNumber: String? = nil
    var sumInsured: String? = nil
    let renewalDate: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
                Text(status)
                    .font(.caption).fontWeight(.semibold).foregroundColor(.orange)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2)).cornerRadius(12)
            }
            VStack(spacing: 8) {
                HStack {
                    Text("Claimed Amount").foregroundColor(.secondary)
                    Spacer()
                    Text(claimedAmount)
                }.font(.subheadline)
                if let reg = registrationNumber {
                    HStack {
                        Text("Registration number").foregroundColor(.secondary)
                        Spacer()
                        Text(reg)
                    }.font(.subheadline)
                }
                if let sum = sumInsured {
                    HStack {
                        Text("Sum Insured").foregroundColor(.secondary)
                        Spacer()
                        Text(sum)
                    }.font(.subheadline)
                }
                HStack {
                    Text("Renewal Date").foregroundColor(.secondary)
                    Spacer()
                    Text(renewalDate)
                }.font(.subheadline)
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }

}
struct ChartLegendItem: View {
    let color: Color
    let label: String
    var dashed: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            if dashed {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(color)
                            .frame(width: 5, height: 3)
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 16, height: 4)
            }
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        InvestmentOverviewView()
            .environment(AppStateManager())
    }
}
