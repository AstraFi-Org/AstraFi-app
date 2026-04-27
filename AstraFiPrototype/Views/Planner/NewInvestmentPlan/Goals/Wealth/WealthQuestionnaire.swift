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
            
            // ── 4. Insight Card
            if showInsights {
                WealthInsightCard(
                    targetAmount: Double(input.targetAmount) ?? 0,
                    savedAmount: Double(input.savedAmount) ?? 0,
                    years: Int(input.targetYears) ?? 1,
                    strategy: input.wealthStrategy ?? .moderate,
                    accentColor: goalAccentColor
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                
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

// MARK: - Wealth Insight Card
struct WealthInsightCard: View {
    let targetAmount: Double
    let savedAmount: Double
    let years: Int
    let strategy: WealthStrategy
    let accentColor: Color
    
    @State private var showFactors = false
    
    private var expectedReturn: Double { strategy.expectedReturn }
    private var netTarget: Double { max(0, targetAmount - savedAmount) }
    
    // Power of compounding over years from savedAmount
    private var futureValueOfSavings: Double {
        savedAmount * pow(1 + expectedReturn, Double(years))
    }
    
    private var additionalNeed: Double {
        max(0, targetAmount - futureValueOfSavings)
    }
    
    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                
                // Header
                HStack {
                    SectionHeader2(
                        icon: "crown.fill",
                        iconColor: accentColor,
                        title: "Wealth Growth Plan",
                        subtitle: "Building your ₹\(fmt(targetAmount)) corpus"
                    )
                    
                    Button { showFactors.toggle() } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18))
                            .foregroundStyle(accentColor)
                    }
                    .sheet(isPresented: $showFactors) {
                        WealthCompoundingSheet(strategy: strategy, accentColor: accentColor)
                            .presentationDetents([.medium, .large])
                    }
                }
                
                Divider()
                
                // Calculations
                VStack(spacing: 12) {
                    detailRow(label: "Current Savings", value: fmt(savedAmount))
                    detailRow(label: "Future Value of Savings (\(Int(expectedReturn*100))%)", 
                              value: fmt(futureValueOfSavings), 
                              color: .green)
                    
                    Divider()
                    
                    detailRow(label: "Additional Goal Gap", 
                              value: fmt(additionalNeed), 
                              color: accentColor,
                              isBold: true)
                }
                
                // Final Net Target
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SIP Savings Needed")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                        Text("To bridge the gap in \(years) yrs")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(accentColor)
                        .font(.title2)
                }
                .padding(14)
                .background(accentColor.opacity(0.07),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                // Advice
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                    Text("In \(strategy.rawValue), your money doubles every \(Int(72 / (expectedReturn * 100))) years. Consistency is more important than the amount.")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    private func detailRow(label: String, value: String, color: Color = .primary, isBold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: isBold ? .bold : .semibold, design: .rounded))
                .foregroundStyle(color)
        }
    }
    
    private func fmt(_ v: Double) -> String {
        if v >= 10_000_000 { return String(format: "₹%.1f Cr", v / 10_000_000) }
        if v >= 100_000    { return String(format: "₹%.1f L", v / 100_000) }
        return "₹\(Int(v).formattedWithComma)"
    }
}

// MARK: - Wealth Compounding Sheet
struct WealthCompoundingSheet: View {
    let strategy: WealthStrategy
    let accentColor: Color
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // 1. Current Scenario Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("The Power of Compounding")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        
                        Text(scenarioText)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal)
                    
                    // 2. Historical Trend Chart
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Growth of ₹1 Lakh (\(Int(strategy.expectedReturn*100))% CAGR)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        
                        HStack(alignment: .bottom, spacing: 8) {
                            let data = historicalData
                            ForEach(data.indices, id: \.self) { index in
                                VStack(spacing: 8) {
                                    Spacer(minLength: 0)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(accentColor.opacity(index == data.count - 1 ? 1.0 : 0.4))
                                        .frame(height: CGFloat(data[index].value) * 1.0) // Scaled
                                    
                                    Text(data[index].year)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 120)
                        
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.caption)
                                .foregroundStyle(accentColor)
                            Text("Wealth multiplies by ~\(Int(totalTenYearGrowth * 100))% every decade at this rate")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // 3. Wealth Factors
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Why this strategy?")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        
                        VStack(spacing: 16) {
                            factorItem(icon: "flame.fill", title: "Market Volatility", desc: "Short-term ups and downs are common in equity but even out over time.")
                            factorItem(icon: "hourglass", title: "Time in Market", desc: "Starting early is more powerful than timing the market correctly.")
                            factorItem(icon: "shield.fill", title: "Asset Allocation", desc: "Diversifying across different stocks reduces the overall risk.")
                            factorItem(icon: "arrow.up.circle.fill", title: "Reinvestment", desc: "Dividends and gains are reinvested to grow your principal amount.")
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 30)
                }
                .padding(.top)
            }
            .navigationTitle("Wealth Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    private var scenarioText: String {
        switch strategy {
        case .aggressive:
            return "Aggressive strategies focus on high-growth sectors and small-cap companies. While volatile in the short run, they have the highest potential to create generational wealth over 15+ years."
        case .moderate:
            return "Moderate equity focuses on established market leaders (Large Caps). It provides steady growth with lower drawdowns compared to aggressive small-cap portfolios."
        case .balanced:
            return "Balanced strategies mix equity with debt to provide a cushion during market crashes. Ideal for those who want wealth growth but have a lower tolerance for sharp price swings."
        case .safe:
            return "Safe strategies prioritize capital preservation. While growth is slower (6-7%), your principal is secure and it provides high liquidity for short-term needs."
        }
    }
    
    private var totalTenYearGrowth: Double {
        let rate = strategy.expectedReturn
        return pow(1 + rate, 10) - 1
    }
    
    private var historicalData: [(year: String, value: Double)] {
        let rate = strategy.expectedReturn
        var base: Double = 20
        var results: [(year: String, value: Double)] = []
        for i in 0..<10 {
            let year = i + 1
            results.append((year: "Yr \(year)", value: base))
            base *= (1 + rate)
        }
        return results
    }
    
    private func factorItem(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        ScrollView {
            WealthQuestionnaire(goalAccentColor: .red)
                .padding()
        }
    }
}
