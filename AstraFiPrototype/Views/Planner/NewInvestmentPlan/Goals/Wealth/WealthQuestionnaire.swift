import SwiftUI

// MARK: - Wealth Plan Input Model
@Observable
class WealthPlanInputModel {
    var targetYears: String = ""
    var targetAmount: String = ""
    var savedAmount: String = ""
    var wealthStrategy: WealthStrategy? = nil
}

enum WealthStrategy: String, CaseIterable {
    case aggressive = "Aggressive Equity"
    case moderate = "Moderate Equity"
    case balanced = "Balanced / Hybrid"
    case safe = "Safe / Fixed Income"
    
    var icon: String {
        switch self {
        case .aggressive: return "chart.line.uptrend.xyaxis"
        case .moderate: return "chart.bar.fill"
        case .balanced: return "scale.3d"
        case .safe: return "lock.shield.fill"
        }
    }
    
    var examples: String {
        switch self {
        case .aggressive: return "Small/Mid Cap Funds, High Growth"
        case .moderate: return "Index Funds, Large Cap Bluechips"
        case .balanced: return "Equity + Debt, Lower Volatility"
        case .safe: return "FD, Liquid Funds, Gold, PPF"
        }
    }
    
    var color: Color {
        switch self {
        case .aggressive: return .red
        case .moderate: return .blue
        case .balanced: return .orange
        case .safe: return .green
        }
    }
    
    var expectedReturn: Double {
        switch self {
        case .aggressive: return 0.15
        case .moderate: return 0.12
        case .balanced: return 0.09
        case .safe: return 0.06
        }
    }
}

// MARK: - Wealth Questionnaire View
struct WealthQuestionnaire: View {
    @State private var input = WealthPlanInputModel()
    let goalAccentColor: Color

    @Environment(AppStateManager.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
    @State private var savingPlan: SavingPlanOption? = nil
    @State private var expectedSIPAmount: String = ""

    var body: some View {
        VStack(spacing: 16) {
            
            // ── 1. Target Card
            SectionCard {
                VStack(spacing: 16) {
                    SectionHeader2(
                        icon: "target",
                        iconColor: goalAccentColor,
                        title: "Wealth Target",
                        subtitle: "What is your wealth goal?"
                    )
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Target Amount (₹)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                            Text("Desired corpus size")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        GoalAmountField(text: $input.targetAmount, placeholder: "e.g. 5 Cr")
                            .frame(width: 120)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Target Years")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                        Spacer()
                        TextField("e.g. 20", text: $input.targetYears)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .frame(width: 80)
                    }
                }
            }
            
            // ── 2. Current Savings Card
            SectionCard {
                VStack(spacing: 16) {
                    SectionHeader2(
                        icon: "indianrupeesign.circle.fill",
                        iconColor: .green,
                        title: "Existing Wealth",
                        subtitle: "What you've already accumulated"
                    )
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Already Saved (₹)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                            Text("Current lumpsum for this goal")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        GoalAmountField(text: $input.savedAmount, placeholder: "e.g. 10L")
                            .frame(width: 120)
                    }
                }
            }
            
            // ── 3. Wealth Strategy Selection Card
            SectionCard {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader2(
                        icon: "brain.headset",
                        iconColor: .blue,
                        title: "Growth Strategy",
                        subtitle: "Risk-Return profile for this goal"
                    )
                    
                    Divider()
                    
                    ForEach(WealthStrategy.allCases, id: \.self) { strategy in
                        WealthStrategyRow(
                            strategy: strategy,
                            isSelected: input.wealthStrategy == strategy,
                            action: { input.wealthStrategy = strategy }
                        )
                        if strategy != .safe { Divider().padding(.leading, 54) }
                    }
                }
            }
            
            if showInsights {
                // ── 5 & 6. Universal Goal Saving Plan Section
                GoalSavingPlanSection(
                    savingPlan: $savingPlan,
                    expectedSIPAmount: $expectedSIPAmount,
                    projectedMFCorpus: projectedMFCorpus,
                    projectedStocksCorpus: projectedStocksCorpus,
                    totalCorpus: additionalNeedValue,
                    goalAccentColor: goalAccentColor,
                    onSave: {
                        let trackerInput = buildTrackerInput()
                        let planModel = InvestmentPlanModel(
                            name: "Wealth Plan",
                            dateSaved: DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none),
                            targetGoal: "Wealth Creation",
                            input: trackerInput
                        )
                        appState.savePlan(planModel)
                        dismiss()
                    },
                    destination: WealthResultView(input: buildTrackerInput())
                )
            }
            
            Spacer(minLength: 40)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: input.wealthStrategy)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showInsights)
    }
    
    private var showInsights: Bool {
        !input.targetAmount.isEmpty &&
        !input.targetYears.isEmpty &&
        input.wealthStrategy != nil
    }
    
    private var projectedMFCorpus: Double {
        let sip = Double(expectedSIPAmount) ?? 0
        let years = Double(input.targetYears) ?? 1
        let months = years * 12
        let rate = 0.12 / 12
        guard rate > 0 && months > 0 else { return 0 }
        return sip * ((pow(1 + rate, months) - 1) / rate) * (1 + rate)
    }

    private var projectedStocksCorpus: Double {
        let sip = Double(expectedSIPAmount) ?? 0
        let years = Double(input.targetYears) ?? 1
        let months = years * 12
        let rate = 0.15 / 12
        guard rate > 0 && months > 0 else { return 0 }
        return sip * ((pow(1 + rate, months) - 1) / rate) * (1 + rate)
    }
    
    private var additionalNeedValue: Double {
        let targetAmt = Double(input.targetAmount) ?? 0
        let savedAmt = Double(input.savedAmount) ?? 0
        let years = Double(input.targetYears) ?? 1
        let expectedReturn = input.wealthStrategy?.expectedReturn ?? 0.12
        let futureValueOfSavings = savedAmt * pow(1 + expectedReturn, years)
        return max(0, targetAmt - futureValueOfSavings)
    }
    
    private func buildTrackerInput() -> InvestmentPlanInputModel {
        var trackerInput = InvestmentPlanInputModel(
            investmentType: "Monthly SIP",
            amount: savingPlan == .sip ? expectedSIPAmount : "0",
            liquidity: "Medium",
            riskType: input.wealthStrategy?.rawValue ?? "Moderate",
            timePeriod: input.targetYears.isEmpty ? "10" : input.targetYears,
            scheduleInvestmentDate: Date(),
            scheduleSIPDate: Date(),
            purposeOfInvestment: "Wealth Creation",
            targetAmount: input.targetAmount.isEmpty ? "0" : input.targetAmount,
            savedAmount: input.savedAmount.isEmpty ? "0" : input.savedAmount,
            hasEmergencyFund: true
        )
        // Wealth-specific data
        trackerInput.wealthIntent = input.wealthStrategy?.rawValue
        trackerInput.goalPlanType = savingPlan?.rawValue
        trackerInput.goalSIPAmount = expectedSIPAmount
        return trackerInput
    }
}

// MARK: - Helper Rows
private struct WealthStrategyRow: View {
    let strategy: WealthStrategy
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(strategy.color.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: strategy.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(strategy.color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(strategy.rawValue)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? strategy.color : .primary)
                    Text(strategy.examples)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(isSelected ? strategy.color : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle().fill(strategy.color).frame(width: 13, height: 13)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    ZStack {
        AppTheme.darkBackground.ignoresSafeArea()
        ScrollView {
            WealthQuestionnaire(goalAccentColor: .red)
                .padding()
        }
    }
}
