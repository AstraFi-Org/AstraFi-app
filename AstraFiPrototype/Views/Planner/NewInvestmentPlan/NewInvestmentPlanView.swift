import SwiftUI

// MARK: - NewInvestmentPlanView
// Step-based questionnaire for Goal-based Planning
//
// Design principles:
//   1. Never re-ask data already in user profile (age, income, EMIs, savings)
//   2. Every question feeds directly into InvestmentPlanInputModel
//   3. Fixed alignment – chips wrap cleanly, no overflow
//   4. Clear visual hierarchy per step

struct NewInvestmentPlanView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppStateManager.self) var appState

    var initialGoal: String

    // ── Navigation ────────────────────────────────────────────────────────────
    @State private var currentStep: Int = 0
    @State private var showResultView = false

    // ── Consolidated State ───────────────────────────────────────────────────
    @State private var input: InvestmentPlanInputModel

    init(initialGoal: String) {
        self.initialGoal = initialGoal
        self._input = State(initialValue: InvestmentPlanInputModel(
            investmentType: "Monthly SIP",
            amount: "",
            liquidity: "Medium",
            riskType: "Moderate",
            timePeriod: "5",
            scheduleInvestmentDate: Date(),
            scheduleSIPDate: Date(),
            purposeOfInvestment: initialGoal,
            targetAmount: "",
            savedAmount: "0",
            hasEmergencyFund: true
        ))
    }

    // Profile shortcuts
    private var profile: AstraUserProfile? { appState.currentProfile }
    private var profileAge: Int? { profile?.basicDetails.age }
    private var profileIncome: Double { profile?.basicDetails.monthlyIncomeAfterTax ?? 0 }
    private var profileEMIs: Double { profile?.loans.reduce(0) { $0 + $1.calculatedEMI } ?? 0 }
    private var profileSavings: Double { profile?.investments.reduce(0) { $0 + $1.investmentAmount } ?? 0 }

    private var steps: [GoalStep] { GoalStep.steps(for: initialGoal, profile: profile) }
    private var totalSteps: Int { steps.count }
    private var progressFraction: Double {
        totalSteps > 1 ? Double(currentStep) / Double(totalSteps - 1) : 1.0
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.appBackground(for: colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                progressHeader

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        stepContent
                        Spacer(minLength: 130)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                }
            }

            bottomNav
        }
        .navigationTitle("\(initialGoal) Plan")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if currentStep > 0 {
                        withAnimation(.spring(response: 0.35)) { currentStep -= 1 }
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
        }
        .navigationDestination(isPresented: $showResultView) {
            let input = buildInputModel()
            switch initialGoal {
            case "Retirement": RetirementResultView(input: input)
            case "Education": EducationResultView(input: input)
            case "Home Purchase": HomeResultView(input: input)
            case "Vehicle": VehicleResultView(input: input)
            case "Travel": TravelResultView(input: input)
            case "Wedding": WeddingResultView(input: input)
            case "Wealth Creation": WealthResultView(input: input)
            case "Business Fund": BusinessResultView(input: input)
            default: OtherResultView(input: input)
            }
        }
        .onAppear {
            if initialGoal == "Retirement", let p = profile {
                let age = p.basicDetails.age
                input.retirementAge = min(65, max(50, age + 25))
                if input.amount.isEmpty {
                    let suggested = (p.basicDetails.monthlyIncomeAfterTax * 0.15).rounded(.toNearestOrEven)
                    input.amount = String(Int(suggested))
                }
            }
        }
    }

    // MARK: - Progress Header
    private var progressHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Step \(currentStep + 1) of \(totalSteps)")
                    .font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                Spacer()
                Text(steps[currentStep].title)
                    .font(.caption).foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(goalAccentColor)
                        .frame(width: geo.size.width * progressFraction, height: 4)
                        .animation(.spring(response: 0.4), value: currentStep)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }

    // MARK: - Bottom Nav
    @ViewBuilder
    private var bottomNav: some View {
        // Bottom nav removed because all goals now use the GoalSavingPlanSection inline.
    }

    // MARK: - Step Content
    @ViewBuilder
    private var stepContent: some View {
        let step = steps[currentStep]

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(step.emoji).font(.title2)
                Text(step.title).font(.title2).fontWeight(.bold)
            }
            Text(step.subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }

        stepFields(for: step.id)
    }

    // MARK: - Step Fields
    @ViewBuilder
    private func stepFields(for stepID: String) -> some View {
        switch stepID {

        // ── SHARED: goal amount + timeline ──────────────────────────────────
        case "target":
            VStack(spacing: 20) {
                AssessmentField(
                    icon: "target",
                    label: "Target Amount for this Goal (₹)",
                    placeholder: "e.g. 50,00,000",
                    text: $input.targetAmount,
                    keyboard: .numberPad
                )

                LabeledField(label: "Time Horizon", icon: "clock.fill",
                             note: "How long do you plan to invest?") {
                    PlanSliderStepper(value: Binding(
                        get: { Int(input.timePeriod) ?? 5 },
                        set: { input.timePeriod = String($0) }
                    ), range: 1...40, unit: "yrs")
                }
                .cardStyle()
            }

        // ── SHARED: SIP amount ───────────────────────────────────────────────
        case "investment":
            VStack(spacing: 20) {
                LabeledField(label: "Investment Mode", icon: "arrow.triangle.2.circlepath") {
                    PlanEnumSegmentChips(selection: Binding(
                        get: { InvestmentMode(rawValue: input.investmentType) ?? .sip },
                        set: { input.investmentType = $0.rawValue }
                    ), options: InvestmentMode.allCases)
                }
                .cardStyle()

                let mode = InvestmentMode(rawValue: input.investmentType) ?? .sip
                if mode == .sip || mode == .hybrid {
                    AssessmentField(
                        icon: "calendar.badge.clock",
                        label: "Monthly SIP Amount (₹)",
                        placeholder: "e.g. 10,000",
                        text: $input.amount,
                        keyboard: .numberPad
                    )
                }

                if mode == .lumpsum || mode == .hybrid {
                    AssessmentField(
                        icon: "briefcase.fill",
                        label: "One-time Lumpsum Amount (₹)",
                        placeholder: "e.g. 5,00,000",
                        text: Binding(
                            get: { input.savedAmount },
                            set: { input.savedAmount = $0 }
                        ),
                        keyboard: .numberPad
                    )
                }

                AssessmentField(
                    icon: "chart.line.uptrend.xyaxis",
                    label: "Annual SIP Step-up (%)",
                    placeholder: "e.g. 10",
                    text: Binding(
                        get: { String(format: "%.0f", input.yearlyStepUpPct ?? 10) },
                        set: { input.yearlyStepUpPct = Double($0) }
                    ),
                    keyboard: .decimalPad
                )
            }

            if profileIncome > 0 {
                ProfileBanner(
                    icon: "person.fill.checkmark",
                    text: "Income: ₹\(fmtL(profileIncome))  ·  EMIs: ₹\(fmtL(profileEMIs))",
                    note: "Auto-filled from your profile – not re-asked"
                )
            }

        // ── SHARED: strategy ─────────────────────────────────────────────────
        case "strategy":
            VStack(spacing: 20) {
                LabeledField(label: "Risk Appetite", icon: "bolt.ring.closed") {
                    PlanEnumSegmentChips(selection: Binding(
                        get: { RiskLevel(rawValue: input.riskType) ?? .mid },
                        set: { input.riskType = $0.rawValue }
                    ), options: RiskLevel.allCases)
                }
                .cardStyle()

                LabeledField(label: "Preferred Asset Class", icon: "chart.pie.fill",
                             note: "Primary growth engine for your money") {
                    VStack(spacing: 8) {
                        ForEach(InvestmentMentality.allCases, id: \.self) { m in
                            PlanAssetRow(mentality: m, isSelected: input.investmentMentality == m) {
                                input.investmentMentality = m
                            }
                        }
                    }
                }
                .cardStyle()

                LabeledField(label: "Liquidity Preference", icon: "drop.fill",
                             note: "How quickly might you need these funds?") {
                    PlanEnumSegmentChips(selection: Binding(
                        get: { LiquidityLevel(rawValue: input.liquidity) ?? .medium },
                        set: { input.liquidity = $0.rawValue }
                    ), options: LiquidityLevel.allCases)
                }
                .cardStyle()
            }

        case "retirement_details", "edu_details", "home_details", "home_finance",
             "vehicle_details", "travel_details", "wedding_details", "wealth_details",
             "business_details", "other_details":
            goalSpecificQuestionnaire(stepId: stepID)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func goalSpecificQuestionnaire(stepId: String) -> some View {
        switch initialGoal {
        case "Retirement":
            RetirementQuestionnaire(
                input: $input,
                stepId: stepId,
                profileAge: profileAge,
                goalAccentColor: goalAccentColor
            )
        case "Education":
            EducationQuestionnaire(
                profileAge: profileAge,
                goalAccentColor: goalAccentColor
            )
        case "Home Purchase":
            HomeQuestionnaire(goalAccentColor: goalAccentColor)
        case "Vehicle":
            VehicleQuestionnaire(goalAccentColor: goalAccentColor)
        case "Travel / Trip":
            TravelQuestionnaire(goalAccentColor: goalAccentColor)
        case "Wedding":
            WeddingQuestionnaire(goalAccentColor: goalAccentColor)
        case "Wealth Creation":
            WealthQuestionnaire(goalAccentColor: goalAccentColor)
        case "Business Fund":
            BusinessQuestionnaire(goalAccentColor: goalAccentColor)
        default:
            OtherQuestionnaire(goalAccentColor: goalAccentColor)
        }
    }

    // MARK: - Build Input Model
    private func buildInputModel() -> InvestmentPlanInputModel {
        var finalInput = input
        finalInput.monthlyIncome = profileIncome
        finalInput.existingEMIs = profileEMIs
        finalInput.savedAmount = profileSavings > 0 ? String(format: "%.0f", profileSavings) : input.savedAmount
        return finalInput
    }

    // MARK: - Helpers
    private var goalAccentColor: Color {
        switch initialGoal {
        case "Retirement":      return .purple
        case "Education":       return .blue
        case "Home Purchase":   return Color(red: 0.13, green: 0.55, blue: 0.26)
        case "Vehicle":         return .orange
        case "Travel / Trip":   return .cyan
        case "Wedding":         return .pink
        case "Wealth Creation": return .indigo
        case "Business Fund":   return .teal
        default:                return .blue
        }
    }

}

// MARK: - Step Model
struct GoalStep: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let emoji: String

//    static func steps(for goal: String, profile: AstraUserProfile?) -> [GoalStep] {
//        let targetStep = GoalStep(id: "target", title: "Your Goal",
//                                  subtitle: "Define what you want to achieve", emoji: "🎯")
//        let sipStep    = GoalStep(id: "investment", title: "Investment Amount",
//                                  subtitle: "How much can you invest monthly?", emoji: "💸")
//        let stratStep  = GoalStep(id: "strategy", title: "Strategy",
//                                  subtitle: "Risk, asset class & liquidity", emoji: "🧠")
//
//        var goalSteps: [GoalStep] = []
//        switch goal {
//        case "Retirement":
//            goalSteps = [
//                GoalStep(id: "retirement_details", title: "Retirement Details",
//                         subtitle: "Timeline, Lifestyle & Strategy", emoji: "🌴")
//            ]
//        case "Education":
//            goalSteps = [
//                GoalStep(id: "edu_details", title: "Education Plan",
//                         subtitle: "Timeline, Cost & Strategy", emoji: "🎓")
//            ]
//        case "Home Purchase":
//            goalSteps = [
//                GoalStep(id: "home_details", title: "Property",
//                         subtitle: "What kind of home are you buying?", emoji: "🏠"),
//                GoalStep(id: "home_finance", title: "Financing",
//                         subtitle: "Down payment & loan preferences", emoji: "🏦"),
//            ]
//        case "Vehicle":
//            goalSteps = [
//                GoalStep(id: "vehicle_details", title: "Vehicle",
//                         subtitle: "Type, segment & loan preference", emoji: "🚗"),
//            ]
//        case "Travel / Trip":
//            goalSteps = [
//                GoalStep(id: "travel_details", title: "Trip Details",
//                         subtitle: "Destination, duration & travellers", emoji: "✈️"),
//            ]
//        case "Wedding":
//            goalSteps = [
//                GoalStep(id: "wedding_details", title: "Wedding",
//                         subtitle: "Scale, venue & funding split", emoji: "💍"),
//            ]
//        case "Wealth Creation":
//            goalSteps = [
//                GoalStep(id: "wealth_details", title: "Wealth Intent",
//                         subtitle: "What does wealth mean to you?", emoji: "💰"),
//            ]
//        case "Business Fund":
//            goalSteps = [
//                GoalStep(id: "business_details", title: "Business",
//                         subtitle: "Type, stage & capital need", emoji: "🏢"),
//            ]
//        default:
//            goalSteps = [
//                GoalStep(id: "other_details", title: "Your Goal",
//                         subtitle: "Tell us more about what you need", emoji: "🎯"),
//            ]
//        }
//
//        // Order: Target → Goal-specific → SIP → Strategy
//        if goal == "Retirement" {
//            return goalSteps + [sipStep, stratStep]
//        } else {
//            return [targetStep] + goalSteps + [sipStep, stratStep]
//        }
//    }
    static func steps(for goal: String, profile: AstraUserProfile?) -> [GoalStep] {
        let targetStep = GoalStep(id: "target", title: "Your Goal",
                                  subtitle: "Define what you want to achieve", emoji: "🎯")
        let sipStep    = GoalStep(id: "investment", title: "Investment Amount",
                                  subtitle: "How much can you invest monthly?", emoji: "💸")
        let stratStep  = GoalStep(id: "strategy", title: "Strategy",
                                  subtitle: "Risk, asset class & liquidity", emoji: "🧠")

        var goalSteps: [GoalStep] = []
        switch goal {
        case "Retirement":
            goalSteps = [
                GoalStep(id: "retirement_details", title: "Retirement Details",
                         subtitle: "Timeline, Lifestyle & Strategy", emoji: "🌴")
            ]
        case "Education":
            goalSteps = [
                GoalStep(id: "edu_details", title: "Education Plan",
                         subtitle: "Timeline, Cost & Strategy", emoji: "🎓")
            ]
        case "Home Purchase":
            goalSteps = [
                GoalStep(id: "home_details", title: "Home Plan",
                         subtitle: "Timeline, Budget & Strategy", emoji: "🏠")
            ]
        case "Vehicle":
            goalSteps = [
                GoalStep(id: "vehicle_details", title: "Vehicle Plan",
                         subtitle: "Timeline, Segment & Strategy", emoji: "🚗"),
            ]
        case "Travel / Trip":
            goalSteps = [
                GoalStep(id: "travel_details", title: "Travel Plan",
                         subtitle: "Timeline, Budget & Strategy", emoji: "✈️"),
            ]
        case "Wedding":
            goalSteps = [
                GoalStep(id: "wedding_details", title: "Wedding Plan",
                         subtitle: "Timeline, Scale & Strategy", emoji: "💍"),
            ]
        case "Wealth Creation":
            goalSteps = [
                GoalStep(id: "wealth_details", title: "Wealth Plan",
                         subtitle: "Target, Timeline & Strategy", emoji: "💰"),
            ]
        case "Business Fund":
            goalSteps = [
                GoalStep(id: "business_details", title: "Business Plan",
                         subtitle: "Timeline, Capital & Strategy", emoji: "🏢"),
            ]
        default:
            goalSteps = [
                GoalStep(id: "other_details", title: "Your Goal",
                         subtitle: "Tell us more about what you need", emoji: "🎯"),
            ]
        }

        // ✅ All specific goals skip the generic steps and use their own standalone questionnaire with GoalSavingPlanSection
        switch goal {
        case "Education", "Retirement", "Home Purchase", "Vehicle", "Travel / Trip", "Wedding", "Wealth Creation", "Business Fund":
            return goalSteps
        default:
            // "Other" goals now also use the standalone questionnaire
            return goalSteps
        }
    }
}

// MARK: - Backward-compatible components (used by other files in the project)

struct FormStepperField: View {
    let label: String; @Binding var value: Int; var range: ClosedRange<Int>
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.footnote).foregroundColor(.secondary).padding(.leading, 4)
            HStack {
                Text("\(value)").font(.body).fontWeight(.bold)
                Spacer()
                Stepper("", value: $value, in: range)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Color(UIColor.secondarySystemBackground).opacity(0.3)).cornerRadius(12)
        }
    }
}

struct FormPickerField<T: Hashable>: View {
    @Environment(\.colorScheme) var colorScheme
    let label: String; @Binding var selection: T; let options: [T]
    var icon: String = "slider.horizontal.3"; var description: String? = nil
    private var labelForOption: (T) -> String {
        { option in (option as? any RawRepresentable)?.rawValue as? String ?? "\(option)" }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.footnote).foregroundColor(.secondary).padding(.leading, 4)
            ZStack {
                HStack {
                    Text(labelForOption(selection)).font(.body).foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundColor(.blue)
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(Color(UIColor.secondarySystemBackground).opacity(colorScheme == .dark ? 0.3 : 1.0))
                .cornerRadius(12)
                Menu {
                    Picker(label, selection: $selection) {
                        ForEach(options, id: \.self) { Text(labelForOption($0)).tag($0) }
                    }
                } label: { Color.white.opacity(0.001) }
            }
            if let desc = description {
                Text(desc).font(.caption2).foregroundStyle(.secondary).padding(.horizontal, 4)
            }
        }
    }
}

struct FormTextField: View {
    @Environment(\.colorScheme) var colorScheme
    let label: String; @Binding var value: String
    var keyboardType: UIKeyboardType = .default; var icon: String = "pencil"
    var description: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.footnote).foregroundColor(.secondary).padding(.leading, 4)
            TextField("Enter Value", text: $value).font(.body).keyboardType(keyboardType)
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(Color(UIColor.secondarySystemBackground).opacity(colorScheme == .dark ? 0.3 : 1.0))
                .cornerRadius(12)
            if let d = description { Text(d).font(.caption2).foregroundColor(.secondary).padding(.leading, 4) }
        }
    }
}

struct FormDateField: View {
    @Environment(\.colorScheme) var colorScheme
    let label: String; @Binding var date: Date
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.footnote).foregroundColor(.secondary).padding(.leading, 4)
            HStack {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact).labelsHidden()
                Spacer(minLength: 40)
            }
            .padding(.vertical, 16)
            .background(Color(UIColor.secondarySystemBackground).opacity(colorScheme == .dark ? 0.3 : 1.0))
            .cornerRadius(12)
        }
    }
}

struct FormToggleField: View {
    let label: String; @Binding var isOn: Bool
    var body: some View {
        Toggle(isOn: $isOn) {
            Text(label).font(.subheadline).foregroundColor(.primary)
        }.padding(.vertical, 4)
    }
}

struct GoalInfoChip: View {
    let icon: String; let text: String
    var body: some View {
        HStack(spacing: 8) {
            Text(icon).font(.title3)
            Text(text).font(.caption).fontWeight(.medium).foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(Color.blue.opacity(0.06)).cornerRadius(10)
    }
}

#Preview {
    NavigationStack {
        NewInvestmentPlanView(initialGoal: "Education")
            .environment(AppStateManager.withSampleData())
    }
}

