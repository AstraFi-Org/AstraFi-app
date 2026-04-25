import SwiftUI

struct RetirementQuestionnaire: View {
    @Binding var input: InvestmentPlanInputModel
    let stepId: String
    let profileAge: Int?
    let goalAccentColor: Color

    @State private var showExpenseSheet = false

    var body: some View {
        VStack(spacing: 24) {

            // 1. Timeline Section
            VStack(spacing: 20) {
                AssessmentField(
                    icon: "clock.fill",
                    label: "When you are planning to retire",
                    placeholder: "e.g. 60",
                    text: Binding(
                        get: { String(input.retirementAge ?? 60) },
                        set: { input.retirementAge = Int($0) }
                    ),
                    keyboard: .numberPad
                )

                if let age = profileAge {
                    ProfileBanner(
                        icon: "person.crop.circle.fill.badge.checkmark",
                        text: "Current age: \(age) years",
                        note: "From your profile"
                    )
                }

                if let age = profileAge, let rAge = input.retirementAge, rAge > age {
                    HStack {
                        Text("Time period for retirement:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Text("\(rAge - age) years")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(goalAccentColor)
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                LabeledField(
                    label: "Years in Retirement",
                    icon: "sun.max.fill",
                    note: "Used to calculate total corpus needed"
                ) {
                    PlanSliderStepper(
                        value: Binding(
                            get: { input.yearsPostRetirement ?? 25 },
                            set: { input.yearsPostRetirement = $0 }
                        ),
                        range: 10...40,
                        unit: "yrs"
                    )
                }
                .cardStyle()
            }

            // 2. Lifestyle Selection Section
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Image(systemName: "hand.tap.fill")
                        .foregroundColor(goalAccentColor)
                    Text("What type of life you want in retirement?")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 4)

                VStack(spacing: 12) {
                    LifestyleChoiceCard(
                        title: "Lavish",
                        description: "Dining in best hotels, trips, pubs & luxury lifestyle",
                        isSelected: input.lifestylePreference == "Lavish",
                        color: .purple
                    ) { input.lifestylePreference = "Lavish" }

                    LifestyleChoiceCard(
                        title: "Normal",
                        description: "Comfortable trips, good food & occasional luxury",
                        isSelected: input.lifestylePreference == "Normal",
                        color: .blue
                    ) { input.lifestylePreference = "Normal" }

                    LifestyleChoiceCard(
                        title: "Average",
                        description: "Essential comforts with budget-friendly trips",
                        isSelected: input.lifestylePreference == "Average",
                        color: .green
                    ) { input.lifestylePreference = "Average" }
                }
            }

            // 3. Dynamic Insights Card
            if let preference = input.lifestylePreference {
                RetirementInsightCard(
                    preference: preference,
                    targetAge: input.retirementAge ?? 60,
                    tenure: input.yearsPostRetirement ?? 25,
                    onInfoTap: { showExpenseSheet = true }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // 4. Plan Section
            VStack(alignment: .leading, spacing: 18) {
                PlanDivider()

                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.orange)
                    Text("What is your Plan?")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 4)

                PlanSegmentChips(
                    selection: Binding(
                        get: { input.retirementPlanType ?? "" },
                        set: { input.retirementPlanType = $0 }
                    ),
                    options: ["Will start SIP", "Bank / FD", "No Plan"]
                )
                .cardStyle()

                if let plan = input.retirementPlanType, !plan.isEmpty {
                    planDetailsView(for: plan)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }

            Spacer(minLength: 40)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: input.lifestylePreference)
        .animation(.spring(), value: input.retirementPlanType)
        .sheet(isPresented: $showExpenseSheet) {
            LifestyleExpenseSheet(preference: input.lifestylePreference ?? "Normal")
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func planDetailsView(for plan: String) -> some View {
        VStack(spacing: 20) {
            if plan == "Will start SIP" {
                AssessmentField(
                    icon: "indianrupeesign.circle.fill",
                    label: "Monthly SIP Amount (₹)",
                    placeholder: "e.g. 50,000",
                    text: Binding(
                        get: { input.retirementSIPAmount ?? "" },
                        set: { input.retirementSIPAmount = $0 }
                    ),
                    keyboard: .numberPad
                )

                if let sipStr = input.retirementSIPAmount, let sip = Double(sipStr), sip > 0 {
                    SIPInsightCard(
                        sipAmount: sip,
                        targetCorpus: getTargetCorpusValue(),
                        yearsToInvest: (input.retirementAge ?? 60) - (profileAge ?? 35)
                    )
                }
            } else if plan == "Bank / FD" {
                VStack(spacing: 20) {
                    LabeledField(label: "Savings Frequency", icon: "calendar") {
                        PlanSegmentChips(
                            selection: Binding(
                                get: { input.retirementFDFrequency ?? "Monthly" },
                                set: { input.retirementFDFrequency = $0 }
                            ),
                            options: ["Monthly", "Quarterly", "Yearly"]
                        )
                    }
                    .cardStyle()

                    AssessmentField(
                        icon: "building.columns.fill",
                        label: "Amount to save (\(input.retirementFDFrequency ?? "Monthly"))",
                        placeholder: "e.g. 20,000",
                        text: Binding(
                            get: { input.retirementFDAmount ?? "" },
                            set: { input.retirementFDAmount = $0 }
                        ),
                        keyboard: .numberPad
                    )

                    if let amtStr = input.retirementFDAmount, let amt = Double(amtStr), amt > 0 {
                        FDInsightCard(
                            amount: amt,
                            frequency: input.retirementFDFrequency ?? "Monthly",
                            targetCorpus: getTargetCorpusValue(),
                            yearsToInvest: (input.retirementAge ?? 60) - (profileAge ?? 35)
                        )
                    }
                }
            } else {
                InsightCard(
                    title: "Planning is Freedom",
                    icon: "flag.checkered",
                    iconColor: .blue,
                    message: "Starting today is your biggest advantage. Every year of delay requires a 20% higher investment later to reach the same goal.",
                    scenarios: [
                        "Compounding works best over time",
                        "Inflation starts eating savings now",
                        "Healthcare costs rise 10% annually"
                    ]
                )
            }
        }
    }

    private func getTargetCorpusValue() -> Double {
        let base: Double
        switch input.lifestylePreference {
        case "Lavish": base = 120_000_000.0
        case "Normal": base = 45_000_000.0
        default:       base = 22_000_000.0
        }
        let tenure = Double(input.yearsPostRetirement ?? 25)
        return base * (tenure / 25.0)
    }
}

// MARK: - FD Insight Card

struct FDInsightCard: View {
    let amount: Double
    let frequency: String
    let targetCorpus: Double
    let yearsToInvest: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Header
            HStack {
                Text("⚠️")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Risk Alert: Low Real Growth")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("FD Returns vs Inflation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary.opacity(0.8))

            // Growth estimate block
            VStack(alignment: .leading, spacing: 12) {
                Text("GROWTH ESTIMATE (7%)")
                    .font(.system(size: 10, weight: .bold))   // intentional micro-label, below caption2
                    .foregroundColor(.secondary)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Saved")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(fmtL(totalSaved))
                            .font(.callout)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Final Value")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(fmtCr(estimatedFinalValue))
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
                .padding(12)
                .background(Color.orange.opacity(0.05))
                .cornerRadius(12)

                Text("While Bank/FD is safe, the real growth after inflation is only ~1% per year.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }

            Divider()

            // Key risks
            VStack(alignment: .leading, spacing: 10) {
                Text("KEY RISKS")
                    .font(.system(size: 10, weight: .bold))   // intentional micro-label, below caption2
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Circle().fill(Color.red.opacity(0.6)).frame(width: 4, height: 4)
                    Text("Tax Impact: FD interest is fully taxable as per your slab.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 8) {
                    Circle().fill(Color.red.opacity(0.6)).frame(width: 4, height: 4)
                    Text("Inflation Risk: Lifestyle costs rise faster than FD interest.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.orange.opacity(0.15), lineWidth: 1)
        )
    }

    private var totalSaved: Double {
        let freqMult: Double = frequency == "Monthly" ? 12 : (frequency == "Quarterly" ? 4 : 1)
        return amount * freqMult * Double(yearsToInvest)
    }

    private var estimatedFinalValue: Double {
        let freqMult: Double = frequency == "Monthly" ? 12 : (frequency == "Quarterly" ? 4 : 1)
        let n = Double(max(1, yearsToInvest)) * freqMult
        let r = 0.07 / freqMult
        return amount * ((pow(1 + r, n) - 1) / r) * (1 + r)
    }

    private var message: String {
        if estimatedFinalValue >= targetCorpus {
            return "Even with FD's conservative returns, your savings of \(fmtL(amount)) \(frequency.lowercased()) will reach your goal. However, taxes will significantly reduce this amount."
        } else {
            return "Your projected FD value of \(fmtCr(estimatedFinalValue)) is far below the target of \(fmtCr(targetCorpus)). You might need to save much more or consider equity/SIP for higher growth."
        }
    }

    private func fmtCr(_ val: Double) -> String {
        if val >= 10_000_000 { return String(format: "₹%.1f Cr", val / 10_000_000) }
        if val >= 100_000    { return String(format: "₹%.1f L",  val / 100_000) }
        return "₹\(Int(val))"
    }

    private func fmtL(_ val: Double) -> String {
        String(format: "₹%.0f L", val / 100_000)
    }
}

// MARK: - SIP Insight Card

struct SIPInsightCard: View {
    let sipAmount: Double
    let targetCorpus: Double
    let yearsToInvest: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Header
            HStack {
                Text(onTrack ? "✅" : "⚠️")
                Text(onTrack ? "You're on track!" : "Gap Detected")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text(onTrack ? "Healthy Plan" : "Adjustment Needed")
                    .font(.caption)
                    .foregroundColor(onTrack ? .green : .orange)
            }

            // Core message
            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary.opacity(0.8))
                .lineSpacing(4)

            // Growth breakdown
            VStack(alignment: .leading, spacing: 12) {
                Text("WEALTH GROWTH BREAKDOWN")
                    .font(.system(size: 10, weight: .bold))   // intentional micro-label, below caption2
                    .foregroundColor(.secondary)

                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Invested")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(fmtL(totalInvested))
                            .font(.callout)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    Image(systemName: "plus")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Growth (12%)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(fmtCr(estimatedGrowth))
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    Spacer()
                    Image(systemName: "equal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Final Value")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(fmtCr(estimatedFinalValue))
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                .padding(12)
                .background(Color.black.opacity(0.03))
                .cornerRadius(12)

                Text("Your wealth grows by \(wealthMultiplier)x through compounding over \(yearsToInvest) years.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }

            Divider()

            // Stress test
            VStack(alignment: .leading, spacing: 14) {
                Text("SCENARIO STRESS TEST")
                    .font(.system(size: 10, weight: .bold))   // intentional micro-label, below caption2
                    .foregroundColor(.secondary)

                VStack(spacing: 12) {
                    ScenarioImpactRow(
                        title: "Medical Emergency",
                        impact: "Withdraw ₹20L at age 50",
                        loss: fmtCr(medicalImpactLoss),
                        icon: "heart.text.square.fill",
                        color: .red
                    )
                    ScenarioImpactRow(
                        title: "Delayed Start",
                        impact: "Starting 5 years later",
                        loss: fmtCr(delayImpactLoss),
                        icon: "clock.badge.exclamationmark.fill",
                        color: .orange
                    )
                }
            }
        }
        .padding(20)
        .background(onTrack ? Color.green.opacity(0.05) : Color.orange.opacity(0.05))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(onTrack ? Color.green.opacity(0.15) : Color.orange.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: Calculations

    private var totalInvested: Double { sipAmount * 12 * Double(yearsToInvest) }

    private var estimatedFinalValue: Double {
        let n = Double(max(1, yearsToInvest)) * 12
        let r = 0.12 / 12
        return sipAmount * ((pow(1 + r, n) - 1) / r) * (1 + r)
    }

    private var estimatedGrowth: Double { estimatedFinalValue - totalInvested }

    private var wealthMultiplier: String { String(format: "%.0f", estimatedFinalValue / totalInvested) }

    private var onTrack: Bool { estimatedFinalValue >= targetCorpus }

    private var medicalImpactLoss: Double {
        2_000_000 * (pow(1.12, 10) - 1)
    }

    private var delayImpactLoss: Double {
        let r = 0.12 / 12
        let nFull    = Double(yearsToInvest) * 12
        let nDelayed = Double(max(0, yearsToInvest - 5)) * 12
        let valFull    = sipAmount * ((pow(1 + r, nFull)    - 1) / r) * (1 + r)
        let valDelayed = sipAmount * ((pow(1 + r, nDelayed) - 1) / r) * (1 + r)
        return valFull - valDelayed
    }

    private var message: String {
        if onTrack {
            return "At 12% expected returns, your monthly SIP of ₹\(Int(sipAmount)) is projected to reach \(fmtCr(estimatedFinalValue)), exceeding your goal of \(fmtCr(targetCorpus))."
        } else {
            let required = calculateRequiredSIP()
            return "To reach \(fmtCr(targetCorpus)) in \(yearsToInvest) years, you need a SIP of ~₹\(Int(required)) monthly. You are currently ₹\(Int(required - sipAmount)) short."
        }
    }

    private func calculateRequiredSIP() -> Double {
        let n = Double(max(1, yearsToInvest)) * 12
        let r = 0.12 / 12
        return targetCorpus * (r / (pow(1 + r, n) - 1)) / (1 + r)
    }

    private func fmtCr(_ val: Double) -> String {
        if val >= 10_000_000 { return String(format: "₹%.1f Cr", val / 10_000_000) }
        if val >= 100_000    { return String(format: "₹%.1f L",  val / 100_000) }
        return "₹\(Int(val))"
    }

    private func fmtL(_ val: Double) -> String {
        String(format: "₹%.0f L", val / 100_000)
    }
}

// MARK: - Scenario Impact Row

struct ScenarioImpactRow: View {
    let title: String
    let impact: String
    let loss: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(impact)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Potential Loss")
                    .font(.system(size: 10, weight: .bold))   // intentional micro-label, below caption2
                    .foregroundColor(.red.opacity(0.8))
                Text("- \(loss)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let message: String
    let scenarios: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon).foregroundColor(iconColor)
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("KEY CONSIDERATIONS")
                    .font(.system(size: 10, weight: .bold))   // intentional micro-label, below caption2
                    .foregroundColor(.secondary)
                ForEach(scenarios, id: \.self) { s in
                    HStack(spacing: 8) {
                        Circle().fill(iconColor.opacity(0.5)).frame(width: 4, height: 4)
                        Text(s)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(iconColor.opacity(0.05))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(iconColor.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Retirement Insight Card

struct RetirementInsightCard: View {
    let preference: String
    let targetAge: Int
    let tenure: Int
    let onInfoTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {

            HStack {
                Text("✨")
                Text(headerTitle)
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: onInfoTap) {
                    Image(systemName: "info.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue.opacity(0.8))
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(insightText)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.primary.opacity(0.8))
                    .lineSpacing(4)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ESTIMATED CORPUS")
                            .font(.system(size: 10, weight: .bold))   // intentional micro-label, below caption2
                            .foregroundColor(.secondary)
                        Text("₹\(estimatedCorpus)")
                            .font(.title2)
                            .fontWeight(.black)
                            .foregroundColor(accentColor)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("MONTHLY BUDGET")
                            .font(.system(size: 10, weight: .bold))   // intentional micro-label, below caption2
                            .foregroundColor(.secondary)
                        Text("₹\(monthlyBudget)")
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                }
                .padding(14)
                .background(accentColor.opacity(0.06))
                .cornerRadius(12)
            }

            VStack(spacing: 12) {
                InsightRow(icon: "chart.line.uptrend.xyaxis", text: "Inflation Impact: 6% p.a. included", color: .red)
                InsightRow(icon: "calendar.badge.clock", text: "Supports lifestyle for \(tenure) years", color: .blue)
            }

            HStack {
                Spacer()
                Text("Based on current market cost estimates")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.blue.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(accentColor.opacity(0.2), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }

    private var accentColor: Color {
        switch preference {
        case "Lavish": return .purple
        case "Normal":  return .blue
        default:        return .green
        }
    }

    private var headerTitle: String {
        switch preference {
        case "Lavish": return "That's smart thinking!"
        case "Normal":  return "Comfortable Planning"
        default:        return "Secure Foundations"
        }
    }

    private var insightText: String {
        switch preference {
        case "Lavish":
            return "Live a grand life with dining at best hotels every 3 days, premium pub visits, and luxury shopping (₹50K+ watches, branded labels). This corpus supports an elite lifestyle for \(tenure) years after retirement."
        case "Normal":
            return "A comfortable life with annual domestic trips, regular dining at good restaurants, and some lavish expenses. Your savings will maintain your standard of living against inflation."
        default:
            return "A simple, budget-conscious life focusing on essentials and local travel. No lavish expenses, but complete peace of mind for \(tenure) years."
        }
    }

    private var estimatedCorpus: String {
        let base: Double
        switch preference {
        case "Lavish": base = 12.0
        case "Normal":  base = 4.5
        default:        base = 2.2
        }
        let adjusted = base * (Double(tenure) / 25.0)
        return String(format: "%.1f Cr", adjusted)
    }

    private var monthlyBudget: String {
        switch preference {
        case "Lavish": return "4.0L+"
        case "Normal":  return "1.5L"
        default:        return "75K"
        }
    }
}

// MARK: - Lifestyle Expense Sheet

struct LifestyleExpenseSheet: View {
    let preference: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection

                    VStack(spacing: 16) {
                        ForEach(expenseBreakdown) { item in
                            LifestyleExpenseRow(item: item)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(16)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Total Estimated Monthly Budget")
                            .font(.headline)
                        Text("₹\(totalAmount)")
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .foregroundColor(accentColor)
                    }
                    .padding(.top, 8)

                    Text("Note: These are estimated monthly expenses in today's currency value. The actual corpus accounts for \(tenureYears) years of inflation and returns.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 12)
                }
                .padding(24)
            }
            .navigationTitle("\(preference) Lifestyle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Assumed Monthly Expenses")
                .font(.title2)
                .fontWeight(.bold)
            Text("Detailed breakdown of what we assume for a \(preference.lowercased()) retirement.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var accentColor: Color {
        switch preference {
        case "Lavish": return .purple
        case "Normal":  return .blue
        default:        return .green
        }
    }

    private var tenureYears: String { "25" }

    private var totalAmount: String {
        switch preference {
        case "Lavish": return "4,50,000"
        case "Normal":  return "1,50,000"
        default:        return "75,000"
        }
    }

    private var expenseBreakdown: [LifestyleExpenseItem] {
        switch preference {
        case "Lavish":
            return [
                LifestyleExpenseItem(name: "Luxury Dining",     amount: "1,50,000", note: "Best hotels every 3 days",       icon: "fork.knife"),
                LifestyleExpenseItem(name: "Travel & Leisure",  amount: "1,00,000", note: "Intl. trips, pubs, golf",        icon: "airplane"),
                LifestyleExpenseItem(name: "Shopping",          amount: "80,000",   note: "Branded labels, ₹50K+ watches",  icon: "bag.fill"),
                LifestyleExpenseItem(name: "Household & Staff", amount: "70,000",   note: "Luxury amenities & services",    icon: "house.fill"),
                LifestyleExpenseItem(name: "Health & Misc",     amount: "50,000",   note: "Premium insurance & personal",   icon: "heart.text.square.fill")
            ]
        case "Normal":
            return [
                LifestyleExpenseItem(name: "Fine Dining",     amount: "40,000", note: "Regular good restaurants",      icon: "fork.knife"),
                LifestyleExpenseItem(name: "Domestic Travel", amount: "30,000", note: "Annual trips, occasional pubs", icon: "airplane"),
                LifestyleExpenseItem(name: "Shopping",        amount: "20,000", note: "Good quality brands",           icon: "bag.fill"),
                LifestyleExpenseItem(name: "Home Utilities",  amount: "15,000", note: "Standard utilities & upkeep",   icon: "house.fill"),
                LifestyleExpenseItem(name: "Health & Misc",   amount: "45,000", note: "Insurance & daily essentials",  icon: "heart.text.square.fill")
            ]
        default:
            return [
                LifestyleExpenseItem(name: "Local Dining",    amount: "15,000", note: "Occasional eating out",         icon: "fork.knife"),
                LifestyleExpenseItem(name: "Budget Travel",   amount: "10,000", note: "Local trips & visits",          icon: "airplane"),
                LifestyleExpenseItem(name: "Shopping",        amount: "10,000", note: "Essential shopping only",       icon: "bag.fill"),
                LifestyleExpenseItem(name: "Home Essentials", amount: "10,000", note: "Standard utilities",            icon: "house.fill"),
                LifestyleExpenseItem(name: "Health & Misc",   amount: "30,000", note: "Essentials & baseline health",  icon: "heart.text.square.fill")
            ]
        }
    }
}

// MARK: - Lifestyle Expense Row

struct LifestyleExpenseItem: Identifiable {
    let id = UUID()
    let name: String
    let amount: String
    let note: String
    let icon: String
}

struct LifestyleExpenseRow: View {
    let item: LifestyleExpenseItem

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: item.icon)
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.callout)
                    .fontWeight(.bold)
                Text(item.note)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("₹\(item.amount)")
                .font(.callout)
                .fontWeight(.bold)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Insight Row

struct InsightRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            Text(text)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(.primary.opacity(0.75))

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppTheme.appBackground(for: .light).ignoresSafeArea()
        RetirementQuestionnaire(
            input: .constant(InvestmentPlanInputModel.sampleRetirement),
            stepId: "retirement_details",
            profileAge: 35,
            goalAccentColor: .purple
        )
    }
}
