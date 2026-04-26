import SwiftUI

// MARK: - Business Plan Input Model
@Observable
class BusinessPlanInputModel {
    var yearsUntilStart: String = ""
    var initialCapitalNeeded: String = ""
    var savedAmount: String = ""
    var businessType: BusinessType? = nil
}

enum BusinessType: String, CaseIterable {
    case techStartup = "Tech Startup"
    case retailOutlet = "Retail / Outlet"
    case serviceAgency = "Service / Agency"
    case sideHustle = "Small Side Hustle"
    
    var icon: String {
        switch self {
        case .techStartup: return "cpu"
        case .retailOutlet: return "cart.fill"
        case .serviceAgency: return "person.3.fill"
        case .sideHustle: return "laptopcomputer"
        }
    }
    
    var examples: String {
        switch self {
        case .techStartup: return "SaaS, Apps, AI, Fintech"
        case .retailOutlet: return "Cafe, Store, Franchise, Salon"
        case .serviceAgency: return "Consulting, Design, Marketing"
        case .sideHustle: return "Freelancing, E-commerce, Content"
        }
    }
    
    var color: Color {
        switch self {
        case .techStartup: return .blue
        case .retailOutlet: return .orange
        case .serviceAgency: return .indigo
        case .sideHustle: return .teal
        }
    }
    
    var annualInflation: Double {
        switch self {
        case .techStartup: return 0.12 // Talent & SaaS tool inflation
        case .retailOutlet: return 0.09 // Rent & raw material inflation
        case .serviceAgency: return 0.07 // Wage & office space inflation
        case .sideHustle: return 0.05 // Hardware & marketing cost hike
        }
    }
}

// MARK: - Business Questionnaire View
struct BusinessQuestionnaire: View {
    @State private var input = BusinessPlanInputModel()
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
                        title: "Launch Timeline",
                        subtitle: "When do you plan to start your business?"
                    )
                    
                    Divider()
                    
                    HStack {
                        Text("Years from now")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("e.g. 3", text: $input.yearsUntilStart)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .frame(width: 80)
                    }
                }
            }
            
            // ── 2. Capital & Savings Card
            SectionCard {
                VStack(spacing: 16) {
                    SectionHeader2(
                        icon: "indianrupeesign.circle.fill",
                        iconColor: .orange,
                        title: "Capital & Savings",
                        subtitle: "Required investment and current fund"
                    )
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Capital Needed (₹)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                            Text("Today's estimated setup cost")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        GoalAmountField(text: $input.initialCapitalNeeded, placeholder: "e.g. 20L")
                            .frame(width: 120)
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Already Saved (₹)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                            Text("Initial seed fund you already have")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        GoalAmountField(text: $input.savedAmount, placeholder: "e.g. 5L")
                            .frame(width: 120)
                    }
                }
            }
            
            // ── 3. Business Type Selection Card
            SectionCard {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader2(
                        icon: "briefcase.fill",
                        iconColor: .blue,
                        title: "Business Type",
                        subtitle: "Setup cost inflation depends on sector"
                    )
                    
                    Divider()
                    
                    ForEach(BusinessType.allCases, id: \.self) { type in
                        BusinessTypeRow(
                            type: type,
                            isSelected: input.businessType == type,
                            action: { input.businessType = type }
                        )
                        if type != .sideHustle { Divider().padding(.leading, 54) }
                    }
                }
            }
            
            // ── 4. Insight Card
            if showInsights {
                BusinessInsightCard(
                    currentCapital: Double(input.initialCapitalNeeded) ?? 0,
                    savedAmount: Double(input.savedAmount) ?? 0,
                    years: Int(input.yearsUntilStart) ?? 1,
                    type: input.businessType ?? .serviceAgency,
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
                            name: "Business Plan",
                            dateSaved: DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none),
                            targetGoal: "Business Fund",
                            input: trackerInput
                        )
                        appState.savePlan(planModel)
                        dismiss()
                    },
                    destination: BusinessResultView(input: buildTrackerInput())
                )
            }
            
            Spacer(minLength: 40)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: input.businessType)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showInsights)
    }
    
    private var showInsights: Bool {
        !input.yearsUntilStart.isEmpty &&
        !input.initialCapitalNeeded.isEmpty &&
        input.businessType != nil
    }
    
    private var projectedMFCorpus: Double {
        let sip = Double(expectedSIPAmount) ?? 0
        let years = Double(input.yearsUntilStart) ?? 1
        let months = years * 12
        let rate = 0.12 / 12
        guard rate > 0 && months > 0 else { return 0 }
        return sip * ((pow(1 + rate, months) - 1) / rate) * (1 + rate)
    }

    private var projectedStocksCorpus: Double {
        let sip = Double(expectedSIPAmount) ?? 0
        let years = Double(input.yearsUntilStart) ?? 1
        let months = years * 12
        let rate = 0.15 / 12
        guard rate > 0 && months > 0 else { return 0 }
        return sip * ((pow(1 + rate, months) - 1) / rate) * (1 + rate)
    }
    
    private var netTargetValue: Double {
        let currentCapital = Double(input.initialCapitalNeeded) ?? 0
        let savedAmt = Double(input.savedAmount) ?? 0
        let years = Double(input.yearsUntilStart) ?? 1
        let inflation = input.businessType?.annualInflation ?? 0.08
        let futureCapital = currentCapital * pow(1 + inflation, years)
        return max(0, futureCapital - savedAmt)
    }
    
    private func buildTrackerInput() -> InvestmentPlanInputModel {
        var trackerInput = InvestmentPlanInputModel(
            investmentType: "Monthly SIP",
            amount: savingPlan == .sip ? expectedSIPAmount : "0",
            liquidity: "Low",
            riskType: "High",
            timePeriod: input.yearsUntilStart.isEmpty ? "5" : input.yearsUntilStart,
            scheduleInvestmentDate: Date(),
            scheduleSIPDate: Date(),
            purposeOfInvestment: "Business Fund",
            targetAmount: String(format: "%.0f", netTargetValue),
            savedAmount: input.savedAmount.isEmpty ? "0" : input.savedAmount,
            hasEmergencyFund: true
        )
        // Business-specific data
        trackerInput.goalPlanType = savingPlan?.rawValue
        trackerInput.goalSIPAmount = expectedSIPAmount
        return trackerInput
    }
}

// MARK: - Helper Rows
private struct BusinessTypeRow: View {
    let type: BusinessType
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

// MARK: - Business Insight Card
struct BusinessInsightCard: View {
    let currentCapital: Double
    let savedAmount: Double
    let years: Int
    let type: BusinessType
    let accentColor: Color
    
    @State private var showFactors = false
    
    private var inflation: Double { type.annualInflation }
    private var futureCapital: Double { currentCapital * pow(1 + inflation, Double(years)) }
    private var priceHike: Double { futureCapital - currentCapital }
    private var netTarget: Double { max(0, futureCapital - savedAmount) }
    
    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                
                // Header
                HStack {
                    SectionHeader2(
                        icon: "rocket.fill",
                        iconColor: accentColor,
                        title: "Capital Goal Plan",
                        subtitle: "Your \(years)-year launch target"
                    )
                    
                    Button { showFactors.toggle() } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18))
                            .foregroundStyle(accentColor)
                    }
                    .sheet(isPresented: $showFactors) {
                        BusinessPriceHikeSheet(type: type, accentColor: accentColor)
                            .presentationDetents([.medium, .large])
                    }
                }
                
                Divider()
                
                // Calculations
                VStack(spacing: 12) {
                    detailRow(label: "Initial Est. Capital", value: fmt(currentCapital))
                    detailRow(label: "Est. Cost Hike (\(Int(inflation*100))%)", 
                              value: "+ " + fmt(priceHike), 
                              color: .orange)
                    
                    Divider()
                    
                    detailRow(label: "Future Capital Needed", 
                              value: fmt(futureCapital), 
                              isBold: true)
                    
                    detailRow(label: "Minus Current Seed Fund", 
                              value: "- " + fmt(savedAmount), 
                              color: .green)
                }
                
                // Final Net Target
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Net Target Fund")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                        Text("Amount to save for launch")
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
                    Text(type == .techStartup 
                         ? "Tech talent costs are growing rapidly (10-15%). Consider offshore teams or early co-founders to manage initial burn."
                         : "Commercial rent and retail operation costs typically rise by 8-10% every year in urban hubs.")
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

// MARK: - Business Factors Sheet
struct BusinessPriceHikeSheet: View {
    let type: BusinessType
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
                        Text("Business Setup Trend (Previous 10 Years)")
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
                            Text("Setup costs for this sector have grown by ~\(Int(totalTenYearGrowth * 100))% since 2014")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // 3. Price Hike Factors
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Capital Inflation Factors")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        
                        VStack(spacing: 16) {
                            factorItem(icon: "person.badge.plus.fill", title: "Talent Acquisition", desc: "Rising salary expectations for skilled workers and specialists.")
                            factorItem(icon: "building.2.fill", title: "Commercial Rent", desc: "Prime office and retail spaces hike rent by 7-10% annually.")
                            factorItem(icon: "gearshape.fill", title: "Compliance & Legal", desc: "Periodic changes in licensing, taxes, and government norms.")
                            factorItem(icon: "antenna.radiowaves.left.and.right", title: "Digital Infrastructure", desc: "Cost of cloud, marketing tools, and specialized software.")
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 30)
                }
                .padding(.top)
            }
            .navigationTitle("Business Insights")
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
        case .techStartup:
            return "Tech startups face the highest inflation in talent costs. While cloud infrastructure is becoming efficient, the cost of acquiring premium software developers is at an all-time high."
        case .retailOutlet:
            return "Physical retail is all about location. High-footfall areas are seeing aggressive rent hikes. Supply chain and raw material costs are also volatile in the food and fashion sectors."
        case .serviceAgency:
            return "Service businesses are wage-sensitive. As living costs in metros rise, agency owners must budget for significant annual salary increments to retain top talent."
        case .sideHustle:
            return "Solopreneurs benefit from the creator economy, but the cost of attention (ads) is rising. Hardware and specialized subscriptions are the primary inflation drivers here."
        }
    }
    
    private var totalTenYearGrowth: Double {
        let rate = type.annualInflation
        return pow(1 + rate, 10) - 1
    }
    
    private var historicalData: [(year: String, value: Double)] {
        let rate = type.annualInflation
        var base: Double = 30
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
            BusinessQuestionnaire(goalAccentColor: .blue)
                .padding()
        }
    }
}
