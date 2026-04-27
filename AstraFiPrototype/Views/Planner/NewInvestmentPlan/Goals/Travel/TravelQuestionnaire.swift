import SwiftUI

// MARK: - Travel Plan Input Model
@Observable
class TravelPlanInputModel {
    var yearsUntilTrip: String = ""
    var currentTripCost: String = ""
    var savedAmount: String = ""
    var tripType: TravelType? = nil
}

enum TravelType: String, CaseIterable {
    case intlLuxury = "International (Premium)"
    case intlBudget = "International (Budget)"
    case domesticFlight = "Domestic (Flight)"
    case domesticRoad = "Domestic (Road/Train)"
    
    var icon: String {
        switch self {
        case .intlLuxury: return "airplane.arrival"
        case .intlBudget: return "airplane.departure"
        case .domesticFlight: return "tram.fill"
        case .domesticRoad: return "car.fill"
        }
    }
    
    var examples: String {
        switch self {
        case .intlLuxury: return "Europe, USA, Japan, Australia"
        case .intlBudget: return "SE Asia, Dubai, Maldives, Bali"
        case .domesticFlight: return "Goa, Ladakh, Kerala, North East"
        case .domesticRoad: return "Weekend getaways, Hills, Nearby cities"
        }
    }
    
    var color: Color {
        switch self {
        case .intlLuxury: return .indigo
        case .intlBudget: return .blue
        case .domesticFlight: return .teal
        case .domesticRoad: return .green
        }
    }
    
    var annualInflation: Double {
        switch self {
        case .intlLuxury: return 0.12 // Forex + premium flight hike
        case .intlBudget: return 0.08 // Competitive budget routes
        case .domesticFlight: return 0.07 // ATF (Fuel) + airport charges
        case .domesticRoad: return 0.05 // Fuel + local hotel inflation
        }
    }
}

// MARK: - Travel Questionnaire View
struct TravelQuestionnaire: View {
    @State private var input = TravelPlanInputModel()
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
                        title: "Trip Timeline",
                        subtitle: "When are you planning this trip?"
                    )
                    
                    Divider()
                    
                    HStack {
                        Text("Years from now")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("e.g. 2", text: $input.yearsUntilTrip)
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
                        subtitle: "Current trip cost and your travel fund"
                    )
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Trip Cost (₹)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                            Text("Today's price for this trip")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        GoalAmountField(text: $input.currentTripCost, placeholder: "e.g. 3L")
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
                        GoalAmountField(text: $input.savedAmount, placeholder: "e.g. 50K")
                            .frame(width: 120)
                    }
                }
            }
            
            // ── 3. Trip Type Selection Card
            SectionCard {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader2(
                        icon: "airplane.circle.fill",
                        iconColor: .blue,
                        title: "Destination Type",
                        subtitle: "Inflation varies by travel sector & Forex"
                    )
                    
                    Divider()
                    
                    ForEach(TravelType.allCases, id: \.self) { type in
                        TravelTypeRow(
                            type: type,
                            isSelected: input.tripType == type,
                            action: { input.tripType = type }
                        )
                        if type != .domesticRoad { Divider().padding(.leading, 54) }
                    }
                }
            }
            
            // ── 4. Insight Card
            if showInsights {
                TravelInsightCard(
                    currentCost: Double(input.currentTripCost) ?? 0,
                    savedAmount: Double(input.savedAmount) ?? 0,
                    years: Int(input.yearsUntilTrip) ?? 1,
                    type: input.tripType ?? .domesticFlight,
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
                            name: "Travel Plan",
                            dateSaved: DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none),
                            targetGoal: "Travel",
                            input: trackerInput
                        )
                        appState.savePlan(planModel)
                        dismiss()
                    },
                    destination: TravelResultView(input: buildTrackerInput())
                )
            }
            
            Spacer(minLength: 40)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: input.tripType)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showInsights)
    }
    
    private var showInsights: Bool {
        !input.yearsUntilTrip.isEmpty &&
        !input.currentTripCost.isEmpty &&
        input.tripType != nil
    }
    
    private var projectedMFCorpus: Double {
        let sip = Double(expectedSIPAmount) ?? 0
        let years = Double(input.yearsUntilTrip) ?? 1
        let months = years * 12
        let rate = 0.12 / 12
        guard rate > 0 && months > 0 else { return 0 }
        return sip * ((pow(1 + rate, months) - 1) / rate) * (1 + rate)
    }

    private var projectedStocksCorpus: Double {
        let sip = Double(expectedSIPAmount) ?? 0
        let years = Double(input.yearsUntilTrip) ?? 1
        let months = years * 12
        let rate = 0.15 / 12
        guard rate > 0 && months > 0 else { return 0 }
        return sip * ((pow(1 + rate, months) - 1) / rate) * (1 + rate)
    }
    
    private var netTargetValue: Double {
        let currentCost = Double(input.currentTripCost) ?? 0
        let savedAmt = Double(input.savedAmount) ?? 0
        let years = Double(input.yearsUntilTrip) ?? 1
        let inflation = input.tripType?.annualInflation ?? 0.08
        let futureCost = currentCost * pow(1 + inflation, years)
        return max(0, futureCost - savedAmt)
    }
    
    private func buildTrackerInput() -> InvestmentPlanInputModel {
        var trackerInput = InvestmentPlanInputModel(
            investmentType: "Monthly SIP",
            amount: savingPlan == .sip ? expectedSIPAmount : "0",
            liquidity: "High",
            riskType: "Low",
            timePeriod: input.yearsUntilTrip.isEmpty ? "2" : input.yearsUntilTrip,
            scheduleInvestmentDate: Date(),
            scheduleSIPDate: Date(),
            purposeOfInvestment: "Travel",
            targetAmount: String(format: "%.0f", netTargetValue),
            savedAmount: input.savedAmount.isEmpty ? "0" : input.savedAmount,
            hasEmergencyFund: true
        )
        // Travel-specific data
        trackerInput.goalPlanType = savingPlan?.rawValue
        trackerInput.goalSIPAmount = expectedSIPAmount
        return trackerInput
    }
}

// MARK: - Helper Rows
private struct TravelTypeRow: View {
    let type: TravelType
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

// MARK: - Travel Insight Card
struct TravelInsightCard: View {
    let currentCost: Double
    let savedAmount: Double
    let years: Int
    let type: TravelType
    let accentColor: Color
    
    @State private var showFactors = false
    
    private var inflation: Double { type.annualInflation }
    private var futureCost: Double { currentCost * pow(1 + inflation, Double(years)) }
    private var priceHike: Double { futureCost - currentCost }
    private var netTarget: Double { max(0, futureCost - savedAmount) }
    
    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                
                // Header
                HStack {
                    SectionHeader2(
                        icon: "globe.americas.fill",
                        iconColor: accentColor,
                        title: "Travel Budget Plan",
                        subtitle: "Your \(years)-year adventure goal"
                    )
                    
                    Button { showFactors.toggle() } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18))
                            .foregroundStyle(accentColor)
                    }
                    .sheet(isPresented: $showFactors) {
                        TravelPriceHikeSheet(type: type, accentColor: accentColor)
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
                        Text("Amount to save for your trip")
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
                    Text(type.rawValue.contains("International") 
                         ? "International travel is sensitive to USD/INR rates. We assume a 3-4% currency depreciation on top of local inflation."
                         : "Domestic hotel prices and airfares usually spike by 6-10% annually during peak seasons.")
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

// MARK: - Travel Factors Sheet
struct TravelPriceHikeSheet: View {
    let type: TravelType
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
                        Text("Travel Cost Trend (Previous 10 Years)")
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
                            Text("Global travel costs have grown by ~\(Int(totalTenYearGrowth * 100))% since 2014")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // 3. Price Hike Factors
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Travel Inflation Factors")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        
                        VStack(spacing: 16) {
                            factorItem(icon: "dollarsign.circle.fill", title: "Forex Volatility", desc: "Indian Rupee's gradual depreciation against the Dollar/Euro.")
                            factorItem(icon: "fuelpump.fill", title: "Aviation Fuel", desc: "Global oil price hikes directly impact airfare tickets.")
                            factorItem(icon: "bed.double.fill", title: "Hospitality Demand", desc: "Increased demand for stays in post-pandemic 'revenge travel' era.")
                            factorItem(icon: "ticket.fill", title: "Dynamic Pricing", desc: "AI-driven hotel and flight pricing based on real-time demand.")
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 30)
                }
                .padding(.top)
            }
            .navigationTitle("Travel Insights")
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
        switch type {
        case .intlLuxury:
            return "Premium international travel is seeing a huge surge. Airfares to USA and Europe are up 30% compared to 2019, driven by high demand and limited flight slots."
        case .intlBudget:
            return "Budget international trips (Thailand, Vietnam) remain accessible but are seeing 8-10% inflation due to higher hotel costs and rising entry visa fees in some regions."
        case .domesticFlight:
            return "Domestic flight prices are highly volatile. While competition is high, ATF price hikes and airport development charges are keeping base fares significantly higher than before."
        case .domesticRoad:
            return "Road trips are becoming expensive due to fuel prices and toll hikes. However, boutique stays and homestays are providing great value for budget-conscious travellers."
        }
    }
    
    private var totalTenYearGrowth: Double {
        let rate = type.annualInflation
        return pow(1 + rate, 10) - 1
    }
    
    private var historicalData: [(year: String, value: Double)] {
        let rate = type.annualInflation
        var base: Double = 25
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
        Color(.systemGroupedBackground).ignoresSafeArea()
        ScrollView {
            TravelQuestionnaire(goalAccentColor: .blue)
                .padding()
        }
    }
}
