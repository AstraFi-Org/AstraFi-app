import SwiftUI

struct EducationQuestionnaire: View {
    @Binding var input: InvestmentPlanInputModel
    let stepId: String
    let goalAccentColor: Color
    
    var body: some View {
        VStack(spacing: 24) {
            // Page Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Secure Their Future")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Education is the best investment you can make for your loved ones.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 8)

            // 1. Timeline & Goal Section
            VStack(spacing: 20) {
                LabeledField(label: "When are you assuming to start education?", icon: "clock.fill",
                             note: "Years from today") {
                    PlanSliderStepper(value: Binding(
                        get: { input.yearsUntilEducation ?? 10 },
                        set: { input.yearsUntilEducation = $0 }
                    ), range: 1...25, unit: "yrs")
                }
                .cardStyle()

                AssessmentField(
                    icon: "indianrupeesign.circle.fill",
                    label: "What amount you will need for the Education purpose?",
                    placeholder: "e.g. 50,00,000",
                    text: $input.targetAmount,
                    keyboard: .numberPad
                )

                LabeledField(label: "What is tenure of the course that you are going to pursue?", icon: "book.fill",
                             note: "Duration of the degree/course") {
                    PlanSliderStepper(value: Binding(
                        get: { input.educationDurationYrs ?? 4 },
                        set: { input.educationDurationYrs = $0 }
                    ), range: 1...6, unit: "yrs")
                }
                .cardStyle()
            }

            // 2. Education Insights Card
            if let targetVal = Double(input.targetAmount.replacingOccurrences(of: ",", with: "")), targetVal > 0 {
                EducationInsightCard(
                    targetAmount: targetVal,
                    yearsUntilStart: input.yearsUntilEducation ?? 10,
                    courseTenure: input.educationDurationYrs ?? 4
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // 3. THE PLAN SECTION
            VStack(alignment: .leading, spacing: 18) {
                PlanDivider()
                
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.orange)
                    Text("What is your Plan?")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .padding(.horizontal, 4)
                
                PlanSegmentChips(
                    selection: Binding(
                        get: { input.goalPlanType ?? "" },
                        set: { input.goalPlanType = $0 }
                    ),
                    options: ["Will start SIP", "Bank / FD", "No Plan"]
                )
                .cardStyle()
                
                if let plan = input.goalPlanType, !plan.isEmpty {
                    planDetailsView(for: plan)
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                               removal: .opacity))
                }
            }
            
            Spacer(minLength: 40)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: input.targetAmount)
        .animation(.spring(), value: input.goalPlanType)
    }
    
    @ViewBuilder
    private func planDetailsView(for plan: String) -> some View {
        VStack(spacing: 20) {
            if plan == "Will start SIP" {
                AssessmentField(
                    icon: "chart.line.uptrend.xyaxis.circle.fill",
                    label: "Monthly SIP Amount (₹)",
                    placeholder: "e.g. 15,000",
                    text: Binding(
                        get: { input.goalSIPAmount ?? "" },
                        set: { input.goalSIPAmount = $0 }
                    ),
                    keyboard: .numberPad
                )
                
                if let sipStr = input.goalSIPAmount, let sip = Double(sipStr), sip > 0 {
                    let targetVal = Double(input.targetAmount.replacingOccurrences(of: ",", with: "")) ?? 0
                    GoalSIPInsightCard(
                        sipAmount: sip,
                        targetCorpus: targetVal,
                        yearsToInvest: input.yearsUntilEducation ?? 10,
                        goalType: "Education"
                    )
                }
            } else if plan == "Bank / FD" {
                VStack(spacing: 20) {
                    LabeledField(label: "Savings Frequency", icon: "calendar") {
                        PlanSegmentChips(
                            selection: Binding(
                                get: { input.goalFDFrequency ?? "Monthly" },
                                set: { input.goalFDFrequency = $0 }
                            ),
                            options: ["Monthly", "Quarterly", "Yearly"]
                        )
                    }
                    .cardStyle()
                    
                    AssessmentField(
                        icon: "building.columns.fill",
                        label: "Amount to save (\(input.goalFDFrequency ?? "Monthly"))",
                        placeholder: "e.g. 20,000",
                        text: Binding(
                            get: { input.goalFDAmount ?? "" },
                            set: { input.goalFDAmount = $0 }
                        ),
                        keyboard: .numberPad
                    )
                    
                    if let amtStr = input.goalFDAmount, let amt = Double(amtStr), amt > 0 {
                        let targetVal = Double(input.targetAmount.replacingOccurrences(of: ",", with: "")) ?? 0
                        GoalFDInsightCard(
                            amount: amt,
                            frequency: input.goalFDFrequency ?? "Monthly",
                            targetCorpus: targetVal,
                            yearsToInvest: input.yearsUntilEducation ?? 10
                        )
                    }
                }
            } else {
                InsightCard(
                    title: "Education is a Priority",
                    icon: "flag.checkered",
                    iconColor: .blue,
                    message: "Education costs are rising at ~10% annually. Delaying your planning by even 2 years can increase the required monthly savings by 25%.",
                    scenarios: ["Admission cycles don't wait", "Currency fluctuation (for abroad)", "Tuition hikes often exceed CPI"]
                )
            }
        }
    }
}

// MARK: - Education Insight Card

struct EducationInsightCard: View {
    let targetAmount: Double
    let yearsUntilStart: Int
    let courseTenure: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("🎓")
                Text("Future Cost Projection")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("With education inflation (10% p.a.), the ₹\(fmtL(targetAmount)) you need today will become:")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.primary.opacity(0.8))
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ESTIMATED COST AT START")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(fmtCr(futureCost))
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.purple)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("COURSE TENURE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        Text("\(courseTenure) Years")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
                .padding(14)
                .background(Color.purple.opacity(0.06))
                .cornerRadius(12)
            }
            
            VStack(spacing: 12) {
                InsightRow(icon: "chart.line.uptrend.xyaxis", text: "Education Inflation: 10% p.a. assumed", color: .red)
                InsightRow(icon: "graduationcap.fill", text: "Covers tuition & living for \(courseTenure) years", color: .blue)
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.purple.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.purple.opacity(0.2), lineWidth: 1))
    }
    
    private var futureCost: Double {
        targetAmount * pow(1.10, Double(yearsUntilStart))
    }
    
    private func fmtCr(_ val: Double) -> String {
        if val >= 10000000 { return String(format: "₹%.1f Cr", val / 10000000.0) }
        return String(format: "₹%.1f L", val / 100000.0)
    }
    
    private func fmtL(_ val: Double) -> String {
        return String(format: "%.0f L", val / 100000.0)
    }
}

// MARK: - Reusable Insight Components (Generic Versions)

struct GoalSIPInsightCard: View {
    let sipAmount: Double
    let targetCorpus: Double
    let yearsToInvest: Int
    let goalType: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(onTrack ? "✅" : "⚠️")
                Text(onTrack ? "Plan is Healthy" : "Gap in Funding")
                    .font(.headline).fontWeight(.bold)
                Spacer()
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("SCENARIOS")
                    .font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Circle().fill(Color.blue.opacity(0.6)).frame(width: 4, height: 4)
                    Text("Wealth growth from returns: \(fmtCr(estimatedGrowth))").font(.caption).foregroundColor(.secondary)
                }
                HStack(spacing: 8) {
                    Circle().fill(Color.orange.opacity(0.6)).frame(width: 4, height: 4)
                    Text("Impact of 2-year delay: -\(fmtCr(delayLoss))").font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(onTrack ? Color.green.opacity(0.05) : Color.orange.opacity(0.05))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(onTrack ? Color.green.opacity(0.2) : Color.orange.opacity(0.2), lineWidth: 1))
    }
    
    private var estimatedFinalValue: Double {
        let n = Double(max(1, yearsToInvest)) * 12
        let r = 0.12 / 12
        return sipAmount * ((pow(1 + r, n) - 1) / r) * (1 + r)
    }
    
    private var estimatedGrowth: Double {
        estimatedFinalValue - (sipAmount * 12 * Double(yearsToInvest))
    }
    
    private var delayLoss: Double {
        let nDelayed = Double(max(0, yearsToInvest - 2)) * 12
        let r = 0.12 / 12
        let valFull = estimatedFinalValue
        let valDelayed = sipAmount * ((pow(1 + r, nDelayed) - 1) / r) * (1 + r)
        return valFull - valDelayed
    }
    
    private var onTrack: Bool { estimatedFinalValue >= targetCorpus }
    
    private var message: String {
        if onTrack {
            return "At 12% returns, your SIP will reach \(fmtCr(estimatedFinalValue)) in \(yearsToInvest) years."
        } else {
            return "Target is \(fmtCr(targetCorpus)). At current SIP, you'll reach \(fmtCr(estimatedFinalValue))."
        }
    }
    
    private func fmtCr(_ val: Double) -> String {
        if val >= 10000000 { return String(format: "₹%.1f Cr", val / 10000000.0) }
        return String(format: "₹%.1f L", val / 100000.0)
    }
}

struct GoalFDInsightCard: View {
    let amount: Double
    let frequency: String
    let targetCorpus: Double
    let yearsToInvest: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🏦")
                Text("FD Projection (7%)")
                    .font(.headline).fontWeight(.bold)
                Spacer()
            }
            
            Text("Your \(frequency.lowercased()) savings will reach \(fmtCr(estimatedFinalValue)) in \(yearsToInvest) years.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
            
            Text("Warning: Education inflation (10%) is higher than FD returns (7%). Your purchasing power will decrease over time.")
                .font(.caption)
                .foregroundColor(.red)
                .italic()
        }
        .padding(20)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.orange.opacity(0.2), lineWidth: 1))
    }
    
    private var estimatedFinalValue: Double {
        let freqMult: Double = frequency == "Monthly" ? 12 : (frequency == "Quarterly" ? 4 : 1)
        let n = Double(max(1, yearsToInvest)) * freqMult
        let r = 0.07 / freqMult
        return amount * ((pow(1 + r, n) - 1) / r) * (1 + r)
    }
    
    private func fmtCr(_ val: Double) -> String {
        if val >= 10000000 { return String(format: "₹%.1f Cr", val / 10000000.0) }
        return String(format: "₹%.1f L", val / 100000.0)
    }
}

#Preview {
    ZStack {
        AppTheme.appBackground(for: .light).ignoresSafeArea()
        ScrollView {
            EducationQuestionnaire(
                input: .constant(InvestmentPlanInputModel.sampleEducation),
                stepId: "edu_details",
                goalAccentColor: .purple
            )
            .padding()
        }
    }
}
