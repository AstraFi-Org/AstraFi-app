import SwiftUI

// MARK: - Wedding Plan Input Model
@Observable
class WeddingPlanInputModel {
    var yearsUntilWedding: String = ""
    var currentWeddingCost: String = ""
    var savedAmount: String = ""
    var weddingScale: WeddingScale? = nil
}

enum WeddingScale: String, CaseIterable {
    case destination = "Destination Wedding"
    case grand = "Grand City Wedding"
    case standard = "Standard Wedding"
    case intimate = "Intimate Ceremony"
    
    var icon: String {
        switch self {
        case .destination: return "airplane.circle.fill"
        case .grand: return "building.columns.fill"
        case .standard: return "hottub.fill"
        case .intimate: return "heart.fill"
        }
    }
    
    var examples: String {
        switch self {
        case .destination: return "Udaipur, Bali, Goa, Thailand"
        case .grand: return "5-Star Hotel, 500+ Guests"
        case .standard: return "Banquet Hall, 200+ Guests"
        case .intimate: return "Family & Close Friends, Small Venue"
        }
    }
    
    var color: Color {
        switch self {
        case .destination: return .purple
        case .grand: return .indigo
        case .standard: return .blue
        case .intimate: return .pink
        }
    }
    
    var annualInflation: Double {
        switch self {
        case .destination: return 0.15 // Peak hospitality & airfare hike
        case .grand: return 0.10 // High catering & venue demand
        case .standard: return 0.07 // Standard service inflation
        case .intimate: return 0.05 // Moderate decor & food costs
        }
    }
}

// MARK: - Wedding Questionnaire View
struct WeddingQuestionnaire: View {
    @State private var input = WeddingPlanInputModel()
    let goalAccentColor: Color

    @Environment(AppStateManager.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
    @State private var savingPlan: SavingPlanOption? = nil
    @State private var expectedSIPAmount: String = ""

    var body: some View {
        VStack(spacing: 16) {
            
            // ── 1. Timeline Card
            SectionCard {
                VStack(spacing: 16) {
                    SectionHeader2(
                        icon: "calendar.badge.clock",
                        iconColor: goalAccentColor,
                        title: "Wedding Timeline",
                        subtitle: "When is the big day planned for?"
                    )
                    
                    Divider()
                    
                    HStack {
                        Text("Years from now")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("e.g. 5", text: $input.yearsUntilWedding)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .frame(width: 80)
                    }
                }
            }
            
            // ── 2. Budget & Savings Card
            SectionCard {
                VStack(spacing: 16) {
                    SectionHeader2(
                        icon: "indianrupeesign.circle.fill",
                        iconColor: .orange,
                        title: "Budget & Savings",
                        subtitle: "Current estimates and existing fund"
                    )
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Est. Budget (₹)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                            Text("Today's price for the scale")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        GoalAmountField(text: $input.currentWeddingCost, placeholder: "e.g. 20L")
                            .frame(width: 120)
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Already Saved (₹)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                            Text("Fund you already have for this")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        GoalAmountField(text: $input.savedAmount, placeholder: "e.g. 2L")
                            .frame(width: 120)
                    }
                }
            }
            
            // ── 3. Wedding Scale Selection Card
            SectionCard {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader2(
                        icon: "sparkles.tv.fill",
                        iconColor: .pink,
                        title: "Wedding Scale",
                        subtitle: "Service costs vary by complexity & scale"
                    )
                    
                    Divider()
                    
                    ForEach(WeddingScale.allCases, id: \.self) { scale in
                        WeddingScaleRow(
                            scale: scale,
                            isSelected: input.weddingScale == scale,
                            action: { input.weddingScale = scale }
                        )
                        if scale != .intimate { Divider().padding(.leading, 54) }
                    }
                }
            }
            
            // ── 4. Insight Card
            if showInsights {
                WeddingInsightCard(
                    currentCost: Double(input.currentWeddingCost) ?? 0,
                    savedAmount: Double(input.savedAmount) ?? 0,
                    years: Int(input.yearsUntilWedding) ?? 1,
                    scale: input.weddingScale ?? .standard,
                    accentColor: goalAccentColor
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                
                // ── 5 & 6. Universal Goal Saving Plan Section
                GoalSavingPlanSection(
                    savingPlan: $savingPlan,
                    expectedSIPAmount: $expectedSIPAmount,
                    projectedMFCorpus: projectedMFCorpus,
                    projectedStocksCorpus: projectedStocksCorpus,
                    totalCorpus: netTargetValue,
                    goalAccentColor: goalAccentColor,
                    onSave: {
                        let trackerInput = buildTrackerInput()
                        let planModel = InvestmentPlanModel(
                            name: "Wedding Plan",
                            dateSaved: DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none),
                            targetGoal: "Wedding",
                            input: trackerInput
                        )
                        appState.savePlan(planModel)
                        dismiss()
                    },
                    destination: WeddingResultView(input: buildTrackerInput())
                )
            }
            
            Spacer(minLength: 40)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: input.weddingScale)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showInsights)
    }
    
    private var showInsights: Bool {
        !input.yearsUntilWedding.isEmpty &&
        !input.currentWeddingCost.isEmpty &&
        input.weddingScale != nil
    }
    
    private var projectedMFCorpus: Double {
        let sip = Double(expectedSIPAmount) ?? 0
        let years = Double(input.yearsUntilWedding) ?? 1
        let months = years * 12
        let rate = 0.12 / 12
        guard rate > 0 && months > 0 else { return 0 }
        return sip * ((pow(1 + rate, months) - 1) / rate) * (1 + rate)
    }

    private var projectedStocksCorpus: Double {
        let sip = Double(expectedSIPAmount) ?? 0
        let years = Double(input.yearsUntilWedding) ?? 1
        let months = years * 12
        let rate = 0.15 / 12
        guard rate > 0 && months > 0 else { return 0 }
        return sip * ((pow(1 + rate, months) - 1) / rate) * (1 + rate)
    }
    
    private var netTargetValue: Double {
        let currentCost = Double(input.currentWeddingCost) ?? 0
        let savedAmt = Double(input.savedAmount) ?? 0
        let years = Double(input.yearsUntilWedding) ?? 1
        let inflation = input.weddingScale?.annualInflation ?? 0.07
        let futureCost = currentCost * pow(1 + inflation, years)
        return max(0, futureCost - savedAmt)
    }
    
    private func buildTrackerInput() -> InvestmentPlanInputModel {
        var trackerInput = InvestmentPlanInputModel(
            investmentType: "Monthly SIP",
            amount: savingPlan == .sip ? expectedSIPAmount : "0",
            liquidity: "Low",
            riskType: "Moderate",
            timePeriod: input.yearsUntilWedding.isEmpty ? "5" : input.yearsUntilWedding,
            scheduleInvestmentDate: Date(),
            scheduleSIPDate: Date(),
            purposeOfInvestment: "Wedding",
            targetAmount: String(format: "%.0f", netTargetValue),
            savedAmount: input.savedAmount.isEmpty ? "0" : input.savedAmount,
            hasEmergencyFund: true
        )
        // Wedding-specific data
        trackerInput.goalPlanType = savingPlan?.rawValue
        trackerInput.goalSIPAmount = expectedSIPAmount
        return trackerInput
    }
}

// MARK: - Helper Rows
private struct WeddingScaleRow: View {
    let scale: WeddingScale
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(scale.color.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: scale.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(scale.color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(scale.rawValue)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? scale.color : .primary)
                    Text(scale.examples)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(isSelected ? scale.color : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle().fill(scale.color).frame(width: 13, height: 13)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Wedding Insight Card
struct WeddingInsightCard: View {
    let currentCost: Double
    let savedAmount: Double
    let years: Int
    let scale: WeddingScale
    let accentColor: Color
    
    @State private var showFactors = false
    
    private var inflation: Double { scale.annualInflation }
    private var futureCost: Double { currentCost * pow(1 + inflation, Double(years)) }
    private var priceHike: Double { futureCost - currentCost }
    private var netTarget: Double { max(0, futureCost - savedAmount) }
    
    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                
                // Header
                HStack {
                    SectionHeader2(
                        icon: "heart.fill",
                        iconColor: accentColor,
                        title: "Wedding Target Plan",
                        subtitle: "Your \(years)-year financial goal"
                    )
                    
                    Button { showFactors.toggle() } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18))
                            .foregroundStyle(accentColor)
                    }
                    .sheet(isPresented: $showFactors) {
                        WeddingPriceHikeSheet(scale: scale, accentColor: accentColor)
                            .presentationDetents([.medium, .large])
                    }
                }
                
                Divider()
                
                // Calculations
                VStack(spacing: 12) {
                    detailRow(label: "Current Price", value: fmt(currentCost))
                    detailRow(label: "Est. Cost Hike (\(Int(inflation*100))%)", 
                              value: "+ " + fmt(priceHike), 
                              color: .orange)
                    
                    Divider()
                    
                    detailRow(label: "Total Future Cost", 
                              value: fmt(futureCost), 
                              isBold: true)
                    
                    detailRow(label: "Minus Existing Savings", 
                              value: "- " + fmt(savedAmount), 
                              color: .green)
                }
                
                // Final Net Target
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Net Target Amount")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                        Text("Amount to save for the big day")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(fmt(netTarget))
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(accentColor)
                }
                .padding(14)
                .background(accentColor.opacity(0.07),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                // Advice
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                    Text("Catering and venue costs are growing at 10-15% annually in India. Booking venues early or choosing off-peak dates can save significantly.")
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

// MARK: - Wedding Factors Sheet
struct WeddingPriceHikeSheet: View {
    let scale: WeddingScale
    let accentColor: Color
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // 1. Current Scenario Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Current Market Scenario")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        
                        Text(scenarioText)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal)
                    
                    // 2. Historical Trend Chart
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Wedding Cost Trend (Previous 10 Years)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        
                        HStack(alignment: .bottom, spacing: 8) {
                            let data = historicalData
                            ForEach(data.indices, id: \.self) { index in
                                VStack(spacing: 8) {
                                    Spacer(minLength: 0)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(accentColor.opacity(index == data.count - 1 ? 1.0 : 0.4))
                                        .frame(height: CGFloat(data[index].value) * 1.5)
                                    
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
                            Text("Hospitality & Catering costs have grown by ~\(Int(totalTenYearGrowth * 100))% since 2014")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // 3. Price Hike Factors
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Wedding Inflation Factors")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        
                        VStack(spacing: 16) {
                            factorItem(icon: "wineglass.fill", title: "Hospitality & Venue", desc: "Premium venues hike prices annually due to high peak-season demand.")
                            factorItem(icon: "fork.knife", title: "Catering Costs", desc: "Rising food inflation and labor costs impact per-plate pricing.")
                            factorItem(icon: "sparkles", title: "Decor & Experience", desc: "Higher demand for unique themes and experiential setups.")
                            factorItem(icon: "camera.fill", title: "Photography & Media", desc: "Specialized wedding cinematography and AI-driven edits.")
                        }
                        .padding()
                        .background(AppTheme.elevatedCardBackground, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 30)
                }
                .padding(.top)
            }
            .navigationTitle("Wedding Insights")
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
        switch scale {
        case .destination:
            return "Destination weddings are the fastest growing segment. Costs for flights and premium hotel blocks in Goa or Rajasthan are seeing 15% annual growth."
        case .grand:
            return "Grand city weddings in metros face massive competition for dates. Top-tier 5-star hotels are now booking 12-18 months in advance with firm pricing."
        case .standard:
            return "Standard weddings are manageable but catering costs (per plate) are rising steadily by 8-10% every year due to raw material inflation."
        case .intimate:
            return "Intimate ceremonies provide the best value. By limiting guest count, you can spend more on high-quality decor and personalized experiences without over-budgeting."
        }
    }
    
    private var totalTenYearGrowth: Double {
        let rate = scale.annualInflation
        return pow(1 + rate, 10) - 1
    }
    
    private var historicalData: [(year: String, value: Double)] {
        let rate = scale.annualInflation
        var base: Double = 20
        var results: [(year: String, value: Double)] = []
        for i in 0..<10 {
            let year = 2014 + i
            results.append((year: "'\(year-2000)", value: base))
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
        AppTheme.darkBackground.ignoresSafeArea()
        ScrollView {
            WeddingQuestionnaire(goalAccentColor: .pink)
                .padding()
        }
    }
}
