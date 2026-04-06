import SwiftUI

struct InvestmentForecast: View {
    @Environment(\.colorScheme) var colorScheme
    var appState: AppStateManager
    @State private var selectedTab: String = "Increase SIP"
    @State private var sipIncrement: Double = 10
    @State private var selectedGoalType: String = "Trip"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Investment Forecast")
                .font(.title3)
                .fontWeight(.bold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    InvestmentForecastPill(icon: "arrow.up.circle.fill", text: "Increase SIP",
                        isSelected: selectedTab == "Increase SIP", activeColor: .blue)
                        { selectedTab = "Increase SIP" }
                    InvestmentForecastPill(icon: "plus.circle.fill", text: "Add Lumpsum",
                        isSelected: selectedTab == "Add Lumpsum", activeColor: .blue)
                        { selectedTab = "Add Lumpsum" }
                    InvestmentForecastPill(icon: "clock.fill", text: "Delay Goal",
                        isSelected: selectedTab == "Delay Goal", activeColor: .blue)
                        { selectedTab = "Delay Goal" }
                    InvestmentForecastPill(icon: "arrow.left.arrow.right", text: "Change Asset",
                        isSelected: selectedTab == "Change Asset", activeColor: .blue)
                        { selectedTab = "Change Asset" }
                }
            }

            VStack(spacing: 24) {

                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "flag.fill")
                            .foregroundColor(.orange)
                        Text("Goal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()

                    let goals = appState.currentProfile?.goals ?? []

                    Menu {
                        if goals.isEmpty {
                            Button("No Goals Found") { }
                        } else {
                            ForEach(goals) { goal in
                                Button(goal.goalName) {
                                    selectedGoalType = goal.goalName
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedGoalType)
                                .font(.subheadline).foregroundColor(.primary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2).foregroundColor(.primary)
                        }
                    }
                }

                let goals = appState.currentProfile?.goals ?? []

                if goals.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "circle.dotted").font(.system(size: 30)).foregroundColor(.secondary)
                        Text("No active goals to forecast")
                            .font(.subheadline).fontWeight(.medium).foregroundColor(.secondary)
                        Text("Start a new plan to see insights.")
                            .font(.caption).foregroundColor(.secondary.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 40)
                } else {

                    if selectedTab == "Increase SIP" {
                        increaseSipContent
                    } else if selectedTab == "Add Lumpsum" {
                        addLumpsumContent
                    } else if selectedTab == "Delay Goal" {
                        delayGoalContent
                    } else if selectedTab == "Change Asset" {
                        changeAssetContent
                    }
                }
            }
            .padding(20)
            .background(AppTheme.cardBackground)
            .cornerRadius(20)
            .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 4)
            .onAppear {

                if let firstGoal = appState.currentProfile?.goals.first?.goalName {
                    if selectedGoalType == "Trip" { 
                         selectedGoalType = firstGoal
                    }
                }
            }
        }
    }

    private var currentGoal: AstraGoal? {
        appState.currentProfile?.goals.first(where: { $0.goalName == selectedGoalType })
    }

    private var goalInvestments: [AstraInvestment] {
        guard let g = currentGoal else { return [] }
        return appState.investments(for: g.id)
    }

    private var baseMonthlySIP: Double {
        goalInvestments.filter { $0.mode == .sip }.reduce(0) { $0 + $1.investmentAmount }
    }

    private var totalCollected: Double {
        guard let g = currentGoal else { return 0 }
        return appState.totalCollected(for: g.id)
    }

    private var targetAmount: Double {
        currentGoal?.targetAmount ?? 100000
    }

    private var monthsLeft: Int {
        guard let targetDate = currentGoal?.targetDate else { return 36 }
        let components = Calendar.current.dateComponents([.month], from: Date(), to: targetDate)
        return max(1, components.month ?? 1)
    }

    @ViewBuilder
    private var increaseSipContent: some View {
        let sipBase = baseMonthlySIP > 0 ? baseMonthlySIP : 5000 
        let extraSIP = (sipBase * sipIncrement / 100)
        let totalNewSIP = sipBase + extraSIP

        let remaining = max(targetAmount - totalCollected, 0)

        let oldMonths = Int(remaining / (sipBase > 0 ? sipBase : 1))
        let newMonths = Int(remaining / (totalNewSIP > 0 ? totalNewSIP : 1))
        let timeSaved = max(0, oldMonths - newMonths)

        let oldYears = Double(oldMonths) / 12.0
        let newYears = Double(newMonths) / 12.0

        let extraTotalValue = extraSIP * Double(monthsLeft) * 1.5 

        Group {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.gray)
                    Text("SIP Increment")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(Int(sipIncrement))%")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            Slider(value: $sipIncrement, in: 0...100, step: 5)
                .accentColor(.blue)

            Divider()

            VStack(spacing: 16) {
                ForecastRow(icon: "calendar", label: "Completion", 
                          value: "From \(String(format: "%.1f", oldYears))y to \(String(format: "%.1f", newYears))y", iconColor: .blue)
                ForecastRow(icon: "percent", label: "Expected Returns", 
                          value: "From 12% - 12.8%", iconColor: .green)
                ForecastRow(icon: "indianrupeesign.circle", label: "Monthly Impact", 
                          value: "+\(Double(extraSIP).toCurrency()) SIP", iconColor: .orange)
                ForecastRow(icon: "chart.bar.fill", label: "Total Gains(5Y)", 
                          value: "+\(Double(extraTotalValue / 1000).toCurrency()) K extra", iconColor: .purple)
            }

            HStack(spacing: 15) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                    .font(.title3)

                Text(timeSaved > 0 
                     ? "If you increase your SIP by \(Int(sipIncrement))%, you will achieve your goal(\(selectedGoalType)) \(timeSaved) Months earlier"
                     : "Small increases in SIP significantly reduce your goal achievement time.")
                    .font(.caption)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
        }
    }

    struct ForecastRow: View {
        let icon: String
        let label: String
        let value: String
        let iconColor: Color

        var body: some View {
            HStack {
                Label(label, systemImage: icon)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .tint(iconColor)
                Spacer()
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
        }
    }

    @State private var lumpsumAmount: Double = 50000

    @ViewBuilder
    private var addLumpsumContent: some View {
        let extraGain = lumpsumAmount * 0.45 
        Group {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "banknote.fill")
                        .foregroundColor(.blue)
                    Text("Lumpsum Amount")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(Double(lumpsumAmount).toCurrency())
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }

            Slider(value: $lumpsumAmount, in: 5000...500000, step: 5000)
                .tint(.blue)

            Divider()

            VStack(spacing: 16) {
                InvestmentForecastDetailRow(icon: "calendar", iconColor: .blue, label: "Completion", value: "Significant Boost", isBoldValue: true)
                InvestmentForecastDetailRow(icon: "percent", iconColor: .green, label: "Expected Returns", value: "13.5%", isBoldValue: true)
                InvestmentForecastDetailRow(icon: "chart.bar.fill", iconColor: .purple, label: "Total Gains(5Y)", value: "+\(Double(extraGain).toCurrency()) extra", isBoldValue: true)
            }

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.blue)
                    .padding(.top, 2)
                Text("Adding a Lumpsum of \(Double(lumpsumAmount).toCurrency()) gives a strong boost to the magic of compounding for your \(selectedGoalType) goal.")
                    .font(.caption)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
    }

    @State private var delayMonths: Double = 6

    @ViewBuilder
    private var delayGoalContent: some View {
        let sipBase = baseMonthlySIP > 0 ? baseMonthlySIP : 5000
        let sipDrop = sipBase * (delayMonths / (Double(monthsLeft) + delayMonths))
        let corpusGain = sipBase * delayMonths * 1.2

        Group {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "hourglass")
                        .foregroundColor(.purple)
                    Text("Delay Time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(Int(delayMonths)) Months")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
            }

            Slider(value: $delayMonths, in: 1...24, step: 1)
                .tint(.purple)

            Divider()

            VStack(spacing: 16) {
                InvestmentForecastDetailRow(icon: "calendar", iconColor: .blue, label: "New Target Date", value: "Delayed by \(Int(delayMonths))m", isBoldValue: true)
                InvestmentForecastDetailRow(icon: "indianrupeesign.circle.fill", iconColor: .orange, label: "Required SIP Drop", value: "-\(Double(sipDrop).toCurrency())", isBoldValue: true)
                InvestmentForecastDetailRow(icon: "chart.bar.fill", iconColor: .purple, label: "Expected Corpus", value: "+\(Double(corpusGain).toCurrency()) higher", isBoldValue: true)
            }

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.purple)
                    .padding(.top, 2)
                Text("Delaying your goal by \(Int(delayMonths)) months heavily reduces your monthly burdern by leveraging longer compounding.")
                    .font(.caption)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)
        }
    }

    @State private var selectedAsset: String = "High Risk Equity"

    @ViewBuilder
    private var changeAssetContent: some View {
        Group {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .foregroundColor(.orange)
                    Text("Target Asset Class")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Menu {
                    Button("High Risk Equity") { selectedAsset = "High Risk Equity" }
                    Button("Balanced Fund") { selectedAsset = "Balanced Fund" }
                    Button("Debt / FD") { selectedAsset = "Debt / FD" }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedAsset)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }

            Divider()

            VStack(spacing: 16) {
                InvestmentForecastDetailRow(icon: "percent", iconColor: .green, label: "New Expected Return", value: selectedAsset == "High Risk Equity" ? "15.0%" : (selectedAsset == "Balanced Fund" ? "10.0%" : "6.5%"), isBoldValue: true)
                InvestmentForecastDetailRow(icon: "exclamationmark.triangle.fill", iconColor: .red, label: "Risk Level", value: selectedAsset == "High Risk Equity" ? "High" : (selectedAsset == "Balanced Fund" ? "Moderate" : "Low"), isBoldValue: true)
                InvestmentForecastDetailRow(icon: "calendar", iconColor: .blue, label: "Estimated Completion", value: selectedAsset == "High Risk Equity" ? "Earlier than planned" : (selectedAsset == "Balanced Fund" ? "On track" : "Will need more time"), isBoldValue: true)
            }

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                    .padding(.top, 2)
                Text("Switching to \(selectedAsset) changes your expected trajectory entirely. Monitor closely as market shifts affect timeline directly.")
                    .font(.caption)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct InvestmentForecastPill: View {
    let icon: String
    let text: String
    let isSelected: Bool
    let activeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(text)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? activeColor : Color(uiColor: .systemGray5))
            .cornerRadius(20)
        }
    }
}

struct InvestmentForecastDetailRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    var isBoldValue: Bool = false

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.caption)
                    .frame(width: 20)
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(isBoldValue ? .bold : .regular)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    let sampleState = AppStateManager.withSampleData()
    return ZStack {
        Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
        InvestmentForecast(appState: sampleState)
    }
}
