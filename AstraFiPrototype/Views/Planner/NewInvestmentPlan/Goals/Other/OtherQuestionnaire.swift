import SwiftUI

// MARK: - Other Plan Input Model
@Observable
class OtherPlanInputModel {
    var goalName: String = ""
    var targetAmount: String = ""
    var targetYears: String = ""
    var savedAmount: String = ""
    var isFlexible: Bool = true
}

// MARK: - Other Questionnaire View
struct OtherQuestionnaire: View {
    @State private var input = OtherPlanInputModel()
    let goalAccentColor: Color

    @Environment(AppStateManager.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
    @State private var savingPlan: SavingPlanOption? = nil
    @State private var expectedSIPAmount: String = ""

    var body: some View {
        VStack(spacing: 16) {
            
            // ── 1. Goal Identity Card
            SectionCard {
                VStack(spacing: 16) {
                    SectionHeader2(
                        icon: "pencil.and.outline",
                        iconColor: goalAccentColor,
                        title: "Goal Details",
                        subtitle: "What are we planning for today?"
                    )
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Goal Name")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        TextField("e.g. Dream Hobby, World Tour", text: $input.goalName)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            
            // ── 2. Timeline & Target Card
            SectionCard {
                VStack(spacing: 16) {
                    SectionHeader2(
                        icon: "target",
                        iconColor: .red,
                        title: "Target & Timeline",
                        subtitle: "When and how much?"
                    )
                    
                    Divider()
                    
                    HStack {
                        Text("Target Amount (₹)")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                        Spacer()
                        TextField("e.g. 10L", text: $input.targetAmount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .frame(width: 120)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Years from now")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                        Spacer()
                        TextField("e.g. 5", text: $input.targetYears)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .frame(width: 80)
                    }
                }
            }
            
            // ── 3. Savings Card
            SectionCard {
                VStack(spacing: 16) {
                    SectionHeader2(
                        icon: "indianrupeesign.circle.fill",
                        iconColor: .green,
                        title: "Existing Savings",
                        subtitle: "What you have already set aside"
                    )
                    
                    Divider()
                    
                    HStack {
                        Text("Already Saved (₹)")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                        Spacer()
                        TextField("e.g. 50K", text: $input.savedAmount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .frame(width: 120)
                    }
                }
            }
            
            // ── 4. Insight Card
            if showInsights {
                OtherInsightCard(
                    targetAmount: Double(input.targetAmount) ?? 0,
                    savedAmount: Double(input.savedAmount) ?? 0,
                    years: Int(input.targetYears) ?? 1,
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
                            name: input.goalName.isEmpty ? "My Goal" : input.goalName,
                            dateSaved: DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none),
                            targetGoal: "Other",
                            input: trackerInput
                        )
                        appState.savePlan(planModel)
                        dismiss()
                    },
                    destination: OtherResultView(input: buildTrackerInput())
                )
            }
            
            Spacer(minLength: 40)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showInsights)
    }
    
    private var showInsights: Bool {
        !input.targetAmount.isEmpty &&
        !input.targetYears.isEmpty
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
    
    private var netTargetValue: Double {
        let targetAmt = Double(input.targetAmount) ?? 0
        let savedAmt = Double(input.savedAmount) ?? 0
        let years = Double(input.targetYears) ?? 1
        // Assume standard 7% inflation for "Other" goals if not specified
        let futureCost = targetAmt * pow(1.07, years)
        return max(0, futureCost - savedAmt)
    }
    
    private func buildTrackerInput() -> InvestmentPlanInputModel {
        var trackerInput = InvestmentPlanInputModel(
            investmentType: "Monthly SIP",
            amount: savingPlan == .sip ? expectedSIPAmount : "0",
            liquidity: "Medium",
            riskType: "Moderate",
            timePeriod: input.targetYears.isEmpty ? "5" : input.targetYears,
            scheduleInvestmentDate: Date(),
            scheduleSIPDate: Date(),
            purposeOfInvestment: "Other",
            targetAmount: String(format: "%.0f", netTargetValue),
            savedAmount: input.savedAmount.isEmpty ? "0" : input.savedAmount,
            hasEmergencyFund: true
        )
        trackerInput.wealthIntent = input.goalName
        trackerInput.goalPlanType = savingPlan?.rawValue
        trackerInput.goalSIPAmount = expectedSIPAmount
        return trackerInput
    }
}

// MARK: - Other Insight Card
struct OtherInsightCard: View {
    let targetAmount: Double
    let savedAmount: Double
    let years: Int
    let accentColor: Color
    
    private var futureCost: Double { targetAmount * pow(1.07, Double(years)) }
    private var netTarget: Double { max(0, futureCost - savedAmount) }
    
    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader2(
                    icon: "sparkles",
                    iconColor: accentColor,
                    title: "Goal Summary",
                    subtitle: "Inflation-adjusted target for \(years) years"
                )
                
                Divider()
                
                VStack(spacing: 12) {
                    detailRow(label: "Today's Cost", value: fmt(targetAmount))
                    detailRow(label: "Inflation Adjusted (7%)", value: fmt(futureCost), color: .orange)
                    detailRow(label: "Already Saved", value: "- " + fmt(savedAmount), color: .green)
                    
                    Divider()
                    
                    HStack {
                        Text("Net Needed")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Spacer()
                        Text(fmt(netTarget))
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(accentColor)
                    }
                    .padding(12)
                    .background(accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
    
    private func detailRow(label: String, value: String, color: Color = .primary) -> some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.system(size: 14, weight: .semibold)).foregroundStyle(color)
        }
    }
    
    private func fmt(_ v: Double) -> String {
        if v >= 10_000_000 { return String(format: "₹%.1f Cr", v / 10_000_000) }
        if v >= 100_000    { return String(format: "₹%.1f L", v / 100_000) }
        return "₹\(Int(v).formattedWithComma)"
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        ScrollView {
            OtherQuestionnaire(goalAccentColor: .blue)
                .padding()
        }
    }
}
