import SwiftUI

struct RetirementResultView: View {
    var input: InvestmentPlanInputModel

    @Environment(AppStateManager.self) private var appState
    @State private var scenario: PlanningScenarioKind = .base
    @State private var customAssumptions: FinancialPlanningAssumptions?
    @State private var showingAssumptions = false
    @State private var showingProjection = false

    private var profile: AstraUserProfile? { appState.currentProfile }
    private var assumptions: FinancialPlanningAssumptions { customAssumptions ?? PlanningScenarioKind.assumptionSet(for: scenario) }
    private var resolvedAssumptions: ResolvedPlanningAssumptions { assumptions.resolved(using: scenario) }
    private var currentAge: Int? { input.currentAge ?? profile?.basicDetails.age }
    private var retirementAge: Int { input.retirementAge ?? 60 }
    private var yearsToRetirement: Int { currentAge.map { max(0, retirementAge - $0) } ?? 0 }
    private var currentExpenses: Double { input.retirementMonthlyExpensesToday ?? profile?.basicDetails.monthlyExpenses ?? 0 }
    private var healthcareExpenses: Double { input.retirementMonthlyHealthcareToday ?? 0 }
    private var currentIncome: Double? {
        if let details = profile?.basicDetails {
            return details.monthlyIncomeAfterTax > 0 ? details.monthlyIncomeAfterTax : details.monthlyIncome
        }
        return input.monthlyIncome > 0 ? input.monthlyIncome : nil
    }
    private var currentInvestments: Double {
        let recorded = profile?.investments.reduce(0) { $0 + max(0, $1.investmentAmount) } ?? 0
        return recorded > 0 ? recorded : max(0, Double(input.savedAmount) ?? 0)
    }
    private var selectedSIP: Double { max(0, Double(input.amount) ?? 0) }
    private var lifeExpectancy: Int { retirementAge + max(1, input.yearsPostRetirement ?? 25) }
    private var safeMonthlyCapacity: Double { FinancialCapacityEngine.evaluateCapacity(profile: profile).availableMonthlyPlanningCapacity }
    private var existingMonthlyCommitments: Double {
        guard profile != nil, let currentIncome else { return 0 }
        return max(0, currentIncome - currentExpenses - safeMonthlyCapacity)
    }
    private var otherGoalAllocations: Double {
        guard let journey = profile?.planningJourney else { return 0 }
        return GoalProjectionEngine.otherGoalMonthlyAllocations(
            journey: journey,
            excludingGoalName: "Retirement",
            availableCapacity: safeMonthlyCapacity,
            mode: "Sequential"
        )
    }

    private var configuration: FinancialGoalConfiguration {
        FinancialGoalConfiguration(
            goalType: .retirement,
            goalName: "Retirement",
            currentAge: currentAge,
            yearsToGoal: yearsToRetirement,
            currentMonthlyIncome: currentIncome,
            currentMonthlyExpenses: profile?.basicDetails.monthlyExpenses ?? currentExpenses,
            retirementLifestyleExpensesToday: currentExpenses,
            currentMonthlyHealthcareExpenses: healthcareExpenses,
            currentInvestments: currentInvestments,
            startingMonthlyInvestment: selectedSIP,
            annualInvestmentStepUp: input.yearlyStepUpPct ?? assumptions.annualSIPStepUpRate,
            retirementAge: retirementAge,
            lifeExpectancy: lifeExpectancy,
            otherGoalMonthlyAllocations: existingMonthlyCommitments + otherGoalAllocations
        )
    }

    private var projection: GoalProjectionResult {
        GoalProjectionEngine.project(
            configuration: configuration,
            assumptions: assumptions,
            lifeEvents: lifeEventLoads
        )
    }

    private var lifeEventLoads: [GoalProjectionEngine.LifeEventLoad] {
        guard let profile, let journey = profile.planningJourney else { return [] }
        return GoalProjectionEngine.lifeEventLoads(profile: profile, journey: journey)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                scenarioPicker
                if !projection.validationMessages.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Complete your retirement details", systemImage: "info.circle.fill")
                            .font(.subheadline.weight(.semibold))
                        ForEach(projection.validationMessages, id: \.self) { message in
                            Text(message).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
                }
                lifestyleCard
                targetCard
                actionCard
                feasibilityCard
                Button {
                    showingProjection = true
                } label: {
                    Label("View detailed projection", systemImage: "chart.xyaxis.line")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
                .buttonStyle(.bordered)
                assumptionsDisclosure
                Text("Illustrative projection based on planning assumptions. Returns, inflation and future income are not guaranteed.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Retirement Plan")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: scenario) { _, _ in customAssumptions = nil }
        .sheet(isPresented: $showingAssumptions) {
            PlanningAssumptionsSheet(assumptions: assumptions, retirementAge: retirementAge, lifeExpectancy: lifeExpectancy) { updated in
                customAssumptions = updated
                var journey = profile?.planningJourney ?? FinancialPlanningJourney()
                journey.assumptions = updated
                appState.updateFinancialPlanningJourney(journey)
            }
        }
        .sheet(isPresented: $showingProjection) {
            RetirementDetailedProjectionView(result: projection)
        }
    }

    private var scenarioPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PLANNING SCENARIO")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Picker("Scenario", selection: $scenario) {
                ForEach(PlanningScenarioKind.allCases) { value in
                    Text(value.rawValue).tag(value)
                }
            }
            .pickerStyle(.segmented)
            Text(scenario.disclaimer)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private var lifestyleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Your retirement lifestyle", systemImage: "house.and.flag")
                .font(.headline)
            valueRow("Today's monthly lifestyle", value: currentExpenses, suffix: "/mo")
            valueRow("Estimated at retirement", value: (projection.retirement?.estimatedMonthlyLifestyleAtRetirement ?? 0) + (projection.retirement?.estimatedMonthlyHealthcareAtRetirement ?? 0), suffix: "/mo", prominent: true)
            Text("Based on \(yearsToRetirement) years and \(percent(resolvedAssumptions.expenseGrowthRate)) general inflation. Healthcare uses its separate \(percent(resolvedAssumptions.healthcareInflationRate)) assumption.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private var targetCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Retirement target", systemImage: "scope")
                .font(.headline)
            Text(projection.requiredCorpus, format: .currency(code: "INR").precision(.fractionLength(0)))
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text("Estimated corpus for \(lifeExpectancy - retirementAge) years of retirement, including separate healthcare inflation and other retirement income only when provided.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private var actionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Your action plan", systemImage: "arrow.up.right.circle")
                .font(.headline)
            valueRow("Starting monthly SIP", value: projection.requiredStartingSIP, suffix: "/mo", prominent: true)
            valueRow("Your selected SIP", value: selectedSIP, suffix: "/mo")
            valueRow("Annual SIP increase", text: percent(configuration.annualInvestmentStepUp ?? resolvedAssumptions.annualSIPStepUpRate))
            valueRow("Investment horizon", text: "\(yearsToRetirement) years")
            valueRow("Projected corpus from selected SIP", value: projection.projectedCorpusFromPlan)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private var feasibilityCard: some View {
        let status = projection.feasibility.status
        return VStack(alignment: .leading, spacing: 8) {
            Label("Feasibility · \(status.rawValue)", systemImage: status.icon)
                .font(.headline)
            Text(projection.feasibility.notes.first ?? status.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if currentIncome == nil {
                Text("Add income and expense details to your financial profile to assess affordability.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private var assumptionsDisclosure: some View {
        Button { showingAssumptions = true } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Planning assumptions").font(.subheadline.weight(.semibold))
                    Text("Inflation \(percent(resolvedAssumptions.inflationRate)) · Income growth \(percent(resolvedAssumptions.incomeGrowthRate)) · Return \(percent(resolvedAssumptions.investmentReturnRate))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func valueRow(_ title: String, value: Double, suffix: String = "", prominent: Bool = false) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value, format: .currency(code: "INR").precision(.fractionLength(0)))
                .fontWeight(prominent ? .semibold : .medium)
                .monospacedDigit()
            if !suffix.isEmpty { Text(suffix).foregroundStyle(.secondary) }
        }
        .font(prominent ? .body : .subheadline)
    }

    private func valueRow(_ title: String, text: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(text).fontWeight(.medium).monospacedDigit()
        }
        .font(.subheadline)
    }

    private func percent(_ value: Double) -> String { "\(Int((value * 100).rounded()))%" }
}

private struct PlanningAssumptionsSheet: View {
    @State private var draft: FinancialPlanningAssumptions
    let assumptions: FinancialPlanningAssumptions
    let retirementAge: Int
    let lifeExpectancy: Int
    let onSave: (FinancialPlanningAssumptions) -> Void
    @Environment(\.dismiss) private var dismiss

    init(assumptions: FinancialPlanningAssumptions, retirementAge: Int, lifeExpectancy: Int, onSave: @escaping (FinancialPlanningAssumptions) -> Void) {
        self.assumptions = assumptions
        self.retirementAge = retirementAge
        self.lifeExpectancy = lifeExpectancy
        self.onSave = onSave
        _draft = State(initialValue: assumptions)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Illustrative assumptions · \(assumptions.scenarioKind?.rawValue ?? "Base")") {
                    sliderRow("General inflation", value: binding(\.inflationRate, fallback: 0.05), range: 0...0.12)
                    sliderRow("Income growth", value: binding(\.incomeGrowthRate, fallback: 0.08), range: 0...0.20)
                    sliderRow("Investment return", value: binding(\.investmentReturnRate, fallback: 0.105), range: 0...0.20)
                    sliderRow("Annual SIP increase", value: binding(\.annualSIPStepUpRate, fallback: 0.10), range: 0...0.30)
                    sliderRow("Retirement withdrawal rate", value: binding(\.retirementWithdrawalRate, fallback: 0.04), range: 0.01...0.10)
                    sliderRow("Healthcare inflation", value: binding(\.healthcareInflationRate, fallback: 0.08), range: 0.03...0.15)
                    LabeledContent("Retirement age", value: "\(retirementAge)")
                    LabeledContent("Life expectancy", value: "\(lifeExpectancy)")
                }
                Section {
                    Text("These values are configurable scenario assumptions for illustration, not guaranteed predictions.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Planning Assumptions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") { draft.expenseGrowthRate = draft.inflationRate; onSave(draft); dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func binding(_ keyPath: WritableKeyPath<FinancialPlanningAssumptions, Double?>, fallback: Double) -> Binding<Double> {
        Binding(get: { draft[keyPath: keyPath] ?? fallback }, set: { draft[keyPath: keyPath] = $0 })
    }

    private func sliderRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int((value.wrappedValue * 100).rounded()))%")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: 0.005)
        }
    }
}

private struct RetirementDetailedProjectionView: View {
    let result: GoalProjectionResult
    @Environment(\.dismiss) private var dismiss

    private var selectedYears: [CashflowProjectionYear] {
        let years = result.yearlyProjection
        guard years.count > 12 else { return years }
        return years.enumerated().compactMap { index, year in
            (index % 5 == 0 || index == years.count - 1) ? year : nil
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Before retirement · \(result.scenario.rawValue) scenario") {
                    ForEach(selectedYears) { year in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Age \(year.age)").font(.headline)
                                Spacer()
                                if year.isRetirementYear { Text("Retirement").font(.caption.weight(.semibold)).foregroundStyle(.blue) }
                            }
                            HStack {
                                metric("Income", year.monthlyIncome)
                                metric("Expenses", year.monthlyExpenses + year.monthlyHealthcare)
                            }
                            HStack {
                                metric("Contribution", year.monthlyContribution)
                                metric("Projected corpus", year.investmentCorpus)
                            }
                        }
                        .padding(.vertical, 3)
                    }
                }
                if let retirement = result.retirement {
                    Section("Retirement drawdown") {
                        ForEach(retirement.drawdown.enumerated().filter { $0.offset % 5 == 0 || $0.offset == retirement.drawdown.count - 1 }.map(\.element)) { year in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Age \(year.age)").font(.headline)
                                metric("Beginning corpus", year.beginningCorpus)
                                metric("Expenses after return and income", year.lifestyleExpense + year.healthcareExpense - year.investmentReturnAmount - year.otherIncome)
                                metric("Ending corpus", max(0, year.endingCorpus))
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
            }
            .navigationTitle("Detailed Projection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }

    private func metric(_ title: String, _ value: Double) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value, format: .currency(code: "INR").precision(.fractionLength(0))).monospacedDigit()
        }
        .font(.caption)
    }
}

#Preview {
    NavigationStack {
        RetirementResultView(input: InvestmentPlanInputModel.sampleRetirement)
            .environment(AppStateManager.withSampleData())
    }
}
