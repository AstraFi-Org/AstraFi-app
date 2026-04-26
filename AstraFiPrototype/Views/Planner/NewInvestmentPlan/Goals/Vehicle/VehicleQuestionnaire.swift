import SwiftUI

// MARK: - Vehicle Plan Input Model
@Observable
class VehiclePlanInputModel {
    var yearsUntilPurchase: String = ""
    var currentVehicleCost: String = ""
    var savedAmount: String = ""
    var vehicleType: VehicleType? = nil
}

enum VehicleType: String, CaseIterable {
    case ev = "Electric (EV)"
    case luxury = "Luxury Car"
    case family = "Family SUV / Sedan"
    case bike = "Two-Wheeler"
    
    var icon: String {
        switch self {
        case .ev: return "bolt.car.fill"
        case .luxury: return "car.side.fill"
        case .family: return "suv.fill"
        case .bike: return "bicycle"
        }
    }
    
    var examples: String {
        switch self {
        case .ev: return "Tesla, Nexon EV, Tata Tiago EV"
        case .luxury: return "BMW, Mercedes, Audi, Jaguar"
        case .family: return "Creta, City, Fortuner, XUV700"
        case .bike: return "Royal Enfield, Activa, Pulsar"
        }
    }
    
    var color: Color {
        switch self {
        case .ev: return .green
        case .luxury: return .purple
        case .family: return .blue
        case .bike: return .orange
        }
    }
    
    var annualInflation: Double {
        switch self {
        case .ev: return 0.04 // Lower due to falling battery costs
        case .luxury: return 0.09 // High due to import duties & premium tech
        case .family: return 0.07 // Standard manufacturing inflation
        case .bike: return 0.05 // Moderate commodity price impact
        }
    }
}

// MARK: - Vehicle Questionnaire View
struct VehicleQuestionnaire: View {
    @State private var input = VehiclePlanInputModel()
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
                        subtitle: "When do you plan to buy your vehicle?"
                    )
                    
                    Divider()
                    
                    HStack {
                        Text("Years from now")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("e.g. 3", text: $input.yearsUntilPurchase)
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
                        subtitle: "Current price and your existing fund"
                    )
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Market Price (₹)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                            Text("Today's price of the model")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        TextField("e.g. 15L", text: $input.currentVehicleCost)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .frame(width: 120)
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Already Saved (₹)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                            Text("Current fund for this goal")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        TextField("e.g. 2L", text: $input.savedAmount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .frame(width: 120)
                    }
                }
            }
            
            // ── 3. Vehicle Type Selection Card
            SectionCard {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader2(
                        icon: "car.2.fill",
                        iconColor: .blue,
                        title: "Vehicle Segment",
                        subtitle: "Price hike depends on segment technology"
                    )
                    
                    Divider()
                    
                    ForEach(VehicleType.allCases, id: \.self) { type in
                        VehicleTypeRow(
                            type: type,
                            isSelected: input.vehicleType == type,
                            action: { input.vehicleType = type }
                        )
                        if type != .bike { Divider().padding(.leading, 54) }
                    }
                }
            }
            
            // ── 4. Insight Card
            if showInsights {
                VehicleInsightCard(
                    currentCost: Double(input.currentVehicleCost) ?? 0,
                    savedAmount: Double(input.savedAmount) ?? 0,
                    years: Int(input.yearsUntilPurchase) ?? 1,
                    type: input.vehicleType ?? .family,
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
                            name: "Vehicle Plan",
                            dateSaved: DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none),
                            targetGoal: "Vehicle",
                            input: trackerInput
                        )
                        appState.savePlan(planModel)
                        dismiss()
                    },
                    destination: VehicleResultView(input: buildTrackerInput())
                )
            }
            
            Spacer(minLength: 40)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: input.vehicleType)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showInsights)
    }
    
    private var showInsights: Bool {
        !input.yearsUntilPurchase.isEmpty &&
        !input.currentVehicleCost.isEmpty &&
        input.vehicleType != nil
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
        let currentCost = Double(input.currentVehicleCost) ?? 0
        let savedAmt = Double(input.savedAmount) ?? 0
        let years = Double(input.yearsUntilPurchase) ?? 1
        let inflation = input.vehicleType?.annualInflation ?? 0.07
        let futureCost = currentCost * pow(1 + inflation, years)
        return max(0, futureCost - savedAmt)
    }
    
    private func buildTrackerInput() -> InvestmentPlanInputModel {
        var trackerInput = InvestmentPlanInputModel(
            investmentType: "Monthly SIP",
            amount: savingPlan == .sip ? expectedSIPAmount : "0",
            liquidity: "High",
            riskType: "Low",
            timePeriod: input.yearsUntilPurchase.isEmpty ? "3" : input.yearsUntilPurchase,
            scheduleInvestmentDate: Date(),
            scheduleSIPDate: Date(),
            purposeOfInvestment: "Vehicle",
            targetAmount: String(format: "%.0f", netTargetValue),
            savedAmount: input.savedAmount.isEmpty ? "0" : input.savedAmount,
            hasEmergencyFund: true
        )
        // Vehicle-specific data
        trackerInput.goalPlanType = savingPlan?.rawValue
        trackerInput.goalSIPAmount = expectedSIPAmount
        return trackerInput
    }
}

// MARK: - Helper Rows
private struct VehicleTypeRow: View {
    let type: VehicleType
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

// MARK: - Vehicle Insight Card
struct VehicleInsightCard: View {
    let currentCost: Double
    let savedAmount: Double
    let years: Int
    let type: VehicleType
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
                        icon: "car.fill",
                        iconColor: accentColor,
                        title: "Vehicle Target Plan",
                        subtitle: "Your \(years)-year financial goal"
                    )
                    
                    Button { showFactors.toggle() } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18))
                            .foregroundStyle(accentColor)
                    }
                    .sheet(isPresented: $showFactors) {
                        VehiclePriceHikeSheet(type: type, accentColor: accentColor)
                            .presentationDetents([.medium, .large])
                    }
                }
                
                Divider()
                
                // Calculations
                VStack(spacing: 12) {
                    detailRow(label: "Current Price", value: fmt(currentCost))
                    detailRow(label: "Est. Price Hike (\(Int(inflation*100))%)", 
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
                        Text("Amount to save for full ownership")
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
                    Text(type == .ev 
                         ? "EV prices are stabilizing as battery tech matures. Waiting might get you better range for the same price."
                         : "Commodity prices and safety regulations typically push car prices up by 5-8% every year.")
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

// MARK: - Vehicle Factors Sheet
struct VehiclePriceHikeSheet: View {
    let type: VehicleType
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
                            Text("Prices for this segment have grown by ~\(Int(totalTenYearGrowth * 100))% since 2014")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // 3. Price Hike Factors
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Appreciation Factors")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        
                        VStack(spacing: 16) {
                            factorItem(icon: "gearshape.2.fill", title: "Regulatory Changes", desc: "Periodic emission norm upgrades (BS6, BS7) increase costs.")
                            factorItem(icon: "cpu", title: "Technology Infusion", desc: "ADAS, premium infotainment, and smart features addition.")
                            factorItem(icon: "leaf.fill", title: "Environmental Cess", desc: "Higher taxes on internal combustion engines vs EVs.")
                            factorItem(icon: "shippingbox.fill", title: "Raw Material Costs", desc: "Fluctuating prices of steel, aluminum, and semiconductors.")
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 30)
                }
                .padding(.top)
            }
            .navigationTitle("Vehicle Insights")
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
        case .ev:
            return "The EV market is maturing rapidly. While battery costs are falling, premium features and software are keeping prices firm. Government subsidies (FAME) play a huge role in current pricing."
        case .luxury:
            return "Luxury cars see the highest price hikes due to import duty fluctuations and the rapid introduction of cutting-edge technology. Resale values also depreciate faster than other segments."
        case .family:
            return "SUV demand is dominating the Indian market. Manufacturers are prioritizing SUVs over hatchbacks, leading to consistent price increases in the ₹15L–₹30L segment."
        case .bike:
            return "The transition to electric scooters is disruptive. Traditional high-performance bikes still hold value but face pressure from rising commodity and safety-feature costs."
        }
    }
    
    private var totalTenYearGrowth: Double {
        let rate = type.annualInflation
        return pow(1 + rate, 10) - 1
    }
    
    private var historicalData: [(year: String, value: Double)] {
        let rate = type.annualInflation
        var base: Double = 35
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
            VehicleQuestionnaire(goalAccentColor: .green)
                .padding()
        }
    }
}
