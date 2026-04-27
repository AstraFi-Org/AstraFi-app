import SwiftUI

// MARK: - Home Plan Input Model
@Observable
class HomePlanInputModel {
    var yearsUntilPurchase: String = ""
    var currentHomeCost: String = ""
    var savedAmount: String = ""
    var locationType: HomeLocationType? = nil
    
    // Inflation logic based on location
    var annualInflationRate: Double {
        guard let location = locationType else { return 0.06 }
        switch location {
        case .highTech: return 0.10
        case .metro: return 0.08
        case .nonMetro: return 0.06
        case .rural: return 0.04
        }
    }
}

enum HomeLocationType: String, CaseIterable {
    case highTech = "High-Tech City"
    case metro = "Metro City"
    case nonMetro = "Growing Town"
    case rural = "Rural Area"
    
    var icon: String {
        switch self {
        case .highTech: return "building.3.fill"
        case .metro: return "building.2.fill"
        case .nonMetro: return "house.lodge.fill"
        case .rural: return "tree.fill"
        }
    }
    
    var examples: String {
        switch self {
        case .highTech: return "Bangalore, Mumbai, Hyderabad"
        case .metro: return "Delhi, Noida, Gurgaon, Pune"
        case .nonMetro: return "Growing towns & Tier 2/3 cities"
        case .rural: return "Villages & quiet countryside"
        }
    }
    
    var color: Color {
        switch self {
        case .highTech: return .indigo
        case .metro: return .blue
        case .nonMetro: return .orange
        case .rural: return .green
        }
    }
}

// MARK: - Home Questionnaire View
struct HomeQuestionnaire: View {
    @State private var input = HomePlanInputModel()
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
                        title: "Purchase Timeline",
                        subtitle: "When do you plan to buy your home?"
                    )
                    
                    Divider()
                    
                    HStack {
                        Text("Years from now")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("e.g. 15", text: $input.yearsUntilPurchase)
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
                        subtitle: "Current property price and your savings"
                    )
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Expected Cost (₹)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                            Text("Today's market value")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        GoalAmountField(text: $input.currentHomeCost, placeholder: "e.g. 50L")
                            .frame(width: 120)
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Already Saved (₹)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                            Text("Lumpsum you have for this goal")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        GoalAmountField(text: $input.savedAmount, placeholder: "e.g. 5L")
                            .frame(width: 120)
                    }
                }
            }
            
            // ── 3. Location Selection Card
            SectionCard {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader2(
                        icon: "map.fill",
                        iconColor: .teal,
                        title: "Location Strategy",
                        subtitle: "Property appreciation varies by city type"
                    )
                    
                    Divider()
                    
                    ForEach(HomeLocationType.allCases, id: \.self) { type in
                        LocationTypeRow(
                            type: type,
                            isSelected: input.locationType == type,
                            action: { input.locationType = type }
                        )
                        if type != .rural { Divider().padding(.leading, 54) }
                    }
                }
            }
            
            // ── 4. Insight Card
            if showInsights {
                HomeInsightCard(
                    currentCost: Double(input.currentHomeCost) ?? 0,
                    savedAmount: Double(input.savedAmount) ?? 0,
                    years: Int(input.yearsUntilPurchase) ?? 1,
                    location: input.locationType ?? .metro,
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
                            name: "Home Plan",
                            dateSaved: DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none),
                            targetGoal: "Home Purchase",
                            input: trackerInput
                        )
                        appState.savePlan(planModel)
                        dismiss()
                    },
                    destination: HomeResultView(input: buildTrackerInput())
                )
            }
            
            Spacer(minLength: 40)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: input.locationType)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showInsights)
    }
    
    private var showInsights: Bool {
        !input.yearsUntilPurchase.isEmpty &&
        !input.currentHomeCost.isEmpty &&
        input.locationType != nil
    }
    
    private var projectedMFCorpus: Double {
        let sip = Double(expectedSIPAmount) ?? 0
        let years = Double(input.yearsUntilPurchase) ?? 1
        let months = years * 12
        let rate = 0.12 / 12
        guard rate > 0 && months > 0 else { return 0 }
        return sip * ((pow(1 + rate, months) - 1) / rate) * (1 + rate)
    }

    private var projectedStocksCorpus: Double {
        let sip = Double(expectedSIPAmount) ?? 0
        let years = Double(input.yearsUntilPurchase) ?? 1
        let months = years * 12
        let rate = 0.15 / 12
        guard rate > 0 && months > 0 else { return 0 }
        return sip * ((pow(1 + rate, months) - 1) / rate) * (1 + rate)
    }
    
    private var netTargetValue: Double {
        let currentCost = Double(input.currentHomeCost) ?? 0
        let savedAmt = Double(input.savedAmount) ?? 0
        let years = Double(input.yearsUntilPurchase) ?? 1
        let futureCost = currentCost * pow(1 + input.annualInflationRate, years)
        return max(0, futureCost - savedAmt)
    }
    
    private func buildTrackerInput() -> InvestmentPlanInputModel {
        var trackerInput = InvestmentPlanInputModel(
            investmentType: "Monthly SIP",
            amount: savingPlan == .sip ? expectedSIPAmount : "0",
            liquidity: "Low",
            riskType: "Moderate",
            timePeriod: input.yearsUntilPurchase.isEmpty ? "15" : input.yearsUntilPurchase,
            scheduleInvestmentDate: Date(),
            scheduleSIPDate: Date(),
            purposeOfInvestment: "Home Purchase",
            targetAmount: String(format: "%.0f", netTargetValue),
            savedAmount: input.savedAmount.isEmpty ? "0" : input.savedAmount,
            hasEmergencyFund: true
        )
        // Home-specific data
        trackerInput.goalPlanType = savingPlan?.rawValue
        trackerInput.goalSIPAmount = expectedSIPAmount
        return trackerInput
    }
}

// MARK: - Helper Rows
private struct LocationTypeRow: View {
    let type: HomeLocationType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(type.color.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: type.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(type.color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.rawValue)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? type.color : .primary)
                    Text(type.examples)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(isSelected ? type.color : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle().fill(type.color).frame(width: 13, height: 13)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Home Insight Card
struct HomeInsightCard: View {
    let currentCost: Double
    let savedAmount: Double
    let years: Int
    let location: HomeLocationType
    let accentColor: Color
    
    @State private var showFactors = false
    
    private var inflation: Double {
        switch location {
        case .highTech: return 0.10
        case .metro: return 0.08
        case .nonMetro: return 0.06
        case .rural: return 0.04
        }
    }
    
    private var futureCost: Double {
        currentCost * pow(1 + inflation, Double(years))
    }
    
    private var priceHike: Double {
        futureCost - currentCost
    }
    
    private var netTarget: Double {
        max(0, futureCost - savedAmount)
    }
    
    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                
                // Header
                HStack {
                    SectionHeader2(
                        icon: "house.fill",
                        iconColor: accentColor,
                        title: "Property Target Plan",
                        subtitle: "Your \(years)-year financial target"
                    )
                    
                    Button { showFactors.toggle() } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18))
                            .foregroundStyle(accentColor)
                    }
                    .sheet(isPresented: $showFactors) {
                        HomePriceHikeSheet(location: location, accentColor: accentColor)
                            .presentationDetents([.medium])
                    }
                }
                
                Divider()
                
                // Calculations
                VStack(spacing: 12) {
                    detailRow(label: "Current Price", value: fmt(currentCost))
                    detailRow(label: "Estimated Price Hike (\(Int(inflation*100))%)", 
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
                        Text("Amount you need to build")
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
                    Text("In \(location.rawValue), property prices double roughly every \(Int(72 / (inflation * 100))) years. Start early to beat this hike.")
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
        return "₹\(Int(v))"
    }
}

// MARK: - Price Hike Factors Sheet
struct HomePriceHikeSheet: View {
    let location: HomeLocationType
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
                        Text("Price Trend (Previous 10 Years)")
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
                            Text("Property prices have grown by ~\(Int(totalTenYearGrowth * 100))% since 2014")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // 3. Price Hike Factors
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Future Appreciation Factors")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        
                        VStack(spacing: 16) {
                            factorItem(icon: "bolt.fill", title: "Infrastructure Growth", desc: "New metros, highways, and flyovers nearby.")
                            factorItem(icon: "briefcase.fill", title: "Commercial Hubs", desc: "Nearby tech parks and offices drive rental demand.")
                            factorItem(icon: "person.2.fill", title: "Demand vs Supply", desc: "High migration to \(location.rawValue) increases prices.")
                            factorItem(icon: "chart.bar.fill", title: "General Inflation", desc: "Rising cost of cement, steel, and labor.")
                        }
                        .padding()
                        .background(AppTheme.elevatedCardBackground, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 30)
                }
                .padding(.top)
            }
            .navigationTitle("Market Insights")
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
        switch location {
        case .highTech:
            return "Demand in IT hubs like Bangalore & Mumbai is at an all-time high. Premium projects are selling fast, and inventory levels are low, pushing prices upward at ~10% annually."
        case .metro:
            return "Stable growth driven by mid-income families and nuclear households. Areas with new Metro connectivity (like Noida Extension or Gurgaon Sec 80+) are seeing rapid appreciation."
        case .nonMetro:
            return "Investors are shifting focus here due to lower entry costs and central development plans (Smart City projects). High potential for long-term capital gains as supply remains balanced."
        case .rural:
            return "Steady but slower growth. Appreciation is mostly driven by primary residence needs and local prosperity. Safe for long-term land holding but has lower liquidity."
        }
    }
    
    private var totalTenYearGrowth: Double {
        let rate = inflationRate
        return pow(1 + rate, 10) - 1
    }
    
    private var historicalData: [(year: String, value: Double)] {
        let rate = inflationRate
        var base: Double = 30
        var results: [(year: String, value: Double)] = []
        for i in 0..<10 {
            let year = 2014 + i
            results.append((year: "'\(year-2000)", value: base))
            base *= (1 + rate)
        }
        return results
    }
    
    private var inflationRate: Double {
        switch location {
        case .highTech: return 0.10
        case .metro: return 0.08
        case .nonMetro: return 0.06
        case .rural: return 0.04
        }
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
            HomeQuestionnaire(goalAccentColor: .blue)
                .padding()
        }
    }
}
