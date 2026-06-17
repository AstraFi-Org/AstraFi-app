import SwiftUI

struct InvestmentForecast: View {
    @Environment(\.colorScheme) var colorScheme
    var appState: AppStateManager

    @State private var selectedTab: String = "Increase SIP"
    @State private var sipIncrement: Double = 10
    @State private var selectedGoalType: String = "Trip"
    @State private var lumpsumAmount: Double = 50000
    @State private var delayMonths: Double = 6
    @State private var selectedAsset: String = "High Risk Equity"

    var body: some View {

        let goals = appState.currentProfile?.goals ?? []

        let currentGoal = goals.first(where: { $0.goalName == selectedGoalType })

        let goalInvestments = currentGoal != nil
            ? appState.investments(for: currentGoal!.id)
            : []

        let baseMonthlySIP = goalInvestments
            .filter { $0.mode == .sip }
            .reduce(0) { $0 + $1.investmentAmount }

        let totalCollected = currentGoal != nil
            ? appState.totalCollected(for: currentGoal!.id)
            : 0

        let targetAmount = currentGoal?.targetAmount ?? 100000

        let monthsLeft: Int = {
            guard let targetDate = currentGoal?.targetDate else { return 36 }
            let comp = Calendar.current.dateComponents([.month], from: Date(), to: targetDate)
            return max(1, comp.month ?? 1)
        }()

        let blendedPortfolioCAGR: Double = {
            let invs = goalInvestments.isEmpty
                ? (appState.currentProfile?.investments ?? [])
                : goalInvestments
            guard !invs.isEmpty else { return 0.12 }
            let totalAmt = invs.reduce(0.0) { $0 + $1.investmentAmount }
            guard totalAmt > 0 else { return 0.12 }
            let weightedRate = invs.reduce(0.0) { $0 + ($1.expectedAnnualRate * $1.investmentAmount) }
            return weightedRate / totalAmt
        }()

        return VStack(alignment: .leading, spacing: 16) {

            Text("Investment Forecast")
                .font(.title3)
                .fontWeight(.bold)

            // MARK: Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    InvestmentForecastPill(icon: "arrow.up.circle.fill", text: "Increase SIP",
                                           isSelected: selectedTab == "Increase SIP", activeColor: .blue) {
                        selectedTab = "Increase SIP"
                    }

                    InvestmentForecastPill(icon: "plus.circle.fill", text: "Add Lumpsum",
                                           isSelected: selectedTab == "Add Lumpsum", activeColor: .blue) {
                        selectedTab = "Add Lumpsum"
                    }

                    InvestmentForecastPill(icon: "clock.fill", text: "Delay Goal",
                                           isSelected: selectedTab == "Delay Goal", activeColor: .blue) {
                        selectedTab = "Delay Goal"
                    }

                    InvestmentForecastPill(icon: "arrow.left.arrow.right", text: "Change Asset",
                                           isSelected: selectedTab == "Change Asset", activeColor: .blue) {
                        selectedTab = "Change Asset"
                    }
                }
            }

            VStack(spacing: 24) {

                // MARK: Goal Selector
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "flag.fill").foregroundColor(.orange)
                        Text("Goal").font(.subheadline).foregroundColor(.secondary)
                    }

                    Spacer()

                    Menu {
                        if goals.isEmpty {
                            Button("No Goals Found") {}
                        } else {
                            ForEach(goals) { goal in
                                Button(goal.goalName) {
                                    selectedGoalType = goal.goalName
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedGoalType)
                            Image(systemName: "chevron.up.chevron.down").font(.caption2)
                        }
                    }
                }

                if goals.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "circle.dotted")
                        Text("No active goals to forecast")
                        Text("Start a new plan to see insights.")
                    }
                } else {

                    // =========================
                    // MARK: Increase SIP
                    // =========================
                    if selectedTab == "Increase SIP" {

                        let sipBase = baseMonthlySIP > 0 ? baseMonthlySIP : 5000
                        let extraSIP = (sipBase * sipIncrement / 100)
                        let totalNewSIP = sipBase + extraSIP

                        let remaining = max(targetAmount - totalCollected, 0)

                        let oldMonths = (remaining / sipBase).safeInt
                        let newMonths = (remaining / totalNewSIP).safeInt
                        let timeSaved = max(0, oldMonths - newMonths)

                        let oldYears = Double(oldMonths) / 12.0
                        let newYears = Double(newMonths) / 12.0

                        let extraTotalValue = extraSIP * Double(monthsLeft) * 1.5

                        VStack(spacing: 16) {

                            HStack {
                                Label("SIP Increment", systemImage: "chart.line.uptrend.xyaxis")
                                Spacer()
                                Text("\(sipIncrement.safeInt)%")
                            }

                            Slider(value: $sipIncrement, in: 0...100, step: 5)

                            Divider()

                            VStack(spacing: 16) {
                                ForecastRow(icon: "calendar", label: "Completion",
                                            value: "From \(String(format: "%.1f", oldYears))y to \(String(format: "%.1f", newYears))y",
                                            iconColor: .blue)

                                ForecastRow(icon: "percent", label: "Expected Returns",
                                            value: "From 12% - 12.8%", iconColor: .green)

                                ForecastRow(icon: "indianrupeesign.circle", label: "Monthly Impact",
                                            value: "+\(Double(extraSIP).toCurrency()) SIP", iconColor: .orange)

                                ForecastRow(icon: "chart.bar.fill", label: "Total Gains(5Y)",
                                            value: "+\(Double(extraTotalValue / 1000).toCurrency()) K extra", iconColor: .purple)
                            }

                            InsightBox(
                                text: "Increase SIP by \(sipIncrement.safeInt)% → goal \(timeSaved) months earlier",
                                color: .orange
                            )
                        }
                    }

                    // =========================
                    // MARK: Add Lumpsum
                    // =========================
                    if selectedTab == "Add Lumpsum" {

                        let fiveYearFV = lumpsumAmount * pow(1 + blendedPortfolioCAGR, 5)
                        let extraGain = fiveYearFV - lumpsumAmount

                        VStack(spacing: 16) {

                            HStack {
                                Label("Lumpsum Amount", systemImage: "banknote.fill")
                                Spacer()
                                Text(Double(lumpsumAmount).toCurrency())
                            }

                            Slider(value: $lumpsumAmount, in: 5000...500000, step: 5000)

                            Divider()

                            VStack(spacing: 16) {
                                InvestmentForecastDetailRow(icon: "calendar", iconColor: .blue,
                                                            label: "Completion", value: "Significant Boost", isBoldValue: true)

                                InvestmentForecastDetailRow(icon: "percent", iconColor: .green,
                                                            label: "Expected Returns",
                                                            value: String(format: "%.1f%%", blendedPortfolioCAGR * 100),
                                                            isBoldValue: true)

                                InvestmentForecastDetailRow(icon: "chart.bar.fill", iconColor: .purple,
                                                            label: "Total Gains(5Y)",
                                                            value: "+\(Double(extraGain).toCurrency()) extra",
                                                            isBoldValue: true)
                            }

                            InsightBox(
                                text: "Adding ₹\(lumpsumAmount.safeInt) boosts compounding significantly.",
                                color: .blue
                            )
                        }
                    }

                    // =========================
                    // MARK: Delay Goal
                    // =========================
                    if selectedTab == "Delay Goal" {

                        let sipBase = baseMonthlySIP > 0 ? baseMonthlySIP : 5000
                        let sipDrop = sipBase * (delayMonths / (Double(monthsLeft) + delayMonths))
                        let corpusGain = sipBase * delayMonths * 1.2

                        VStack(spacing: 16) {

                            HStack {
                                Label("Delay Time", systemImage: "hourglass")
                                Spacer()
                                Text("\(delayMonths.safeInt) Months")
                            }

                            Slider(value: $delayMonths, in: 1...24, step: 1)

                            Divider()

                            VStack(spacing: 16) {
                                InvestmentForecastDetailRow(icon: "calendar", iconColor: .blue,
                                                            label: "New Target Date",
                                                            value: "Delayed by \(delayMonths.safeInt)m", isBoldValue: true)

                                InvestmentForecastDetailRow(icon: "indianrupeesign.circle.fill", iconColor: .orange,
                                                            label: "Required SIP Drop",
                                                            value: "-\(Double(sipDrop).toCurrency())", isBoldValue: true)

                                InvestmentForecastDetailRow(icon: "chart.bar.fill", iconColor: .purple,
                                                            label: "Expected Corpus",
                                                            value: "+\(Double(corpusGain).toCurrency())", isBoldValue: true)
                            }

                            InsightBox(
                                text: "Delay reduces monthly burden using compounding.",
                                color: .purple
                            )
                        }
                    }

                    // =========================
                    // MARK: Change Asset
                    // =========================
                    if selectedTab == "Change Asset" {

                        VStack(spacing: 16) {

                            HStack {
                                Label("Target Asset", systemImage: "arrow.left.arrow.right")
                                Spacer()
                                Text(selectedAsset)
                            }

                            Menu {
                                Button("High Risk Equity") { selectedAsset = "High Risk Equity" }
                                Button("Balanced Fund") { selectedAsset = "Balanced Fund" }
                                Button("Debt / FD") { selectedAsset = "Debt / FD" }
                            } label: {
                                Text("Change")
                            }

                            Divider()

                            VStack(spacing: 16) {
                                InvestmentForecastDetailRow(icon: "percent", iconColor: .green,
                                                            label: "Return",
                                                            value: selectedAsset == "High Risk Equity" ? "15%" : "6.5%",
                                                            isBoldValue: true)

                                InvestmentForecastDetailRow(icon: "exclamationmark.triangle.fill",
                                                            iconColor: .red,
                                                            label: "Risk",
                                                            value: selectedAsset == "High Risk Equity" ? "High" : "Low",
                                                            isBoldValue: true)
                            }

                            InsightBox(
                                text: "Asset choice directly impacts returns & risk.",
                                color: .orange
                            )
                        }
                    }
                }
            }
            .padding(20)
            .background(AppTheme.cardBackground)
            .cornerRadius(20)
            .shadow(color: AppTheme.adaptiveShadow, radius: 10)
        }
    }
}

#Preview {
    let sampleState = AppStateManager.withSampleData()

    ZStack {
        Color(uiColor: .systemGroupedBackground)
            .ignoresSafeArea()

        InvestmentForecast(appState: sampleState)
            .padding()
    }
}
