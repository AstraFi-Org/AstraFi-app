import SwiftUI

private struct JourneyGoalNeed: Identifiable {
    let id: UUID
    let name: String
    let date: Date
    let monthlyNeed: Double
}

private struct JourneyPriorityItem: Identifiable {
    let id: UUID
    let name: String
    let detail: String
    let category: String
}

private struct JourneyTimelineEntry: Identifiable {
    let id: UUID
    let name: String
    let detail: String
    let date: Date?
    let amount: Double?
    let priority: Int
    let category: String
    let isEvent: Bool
}

private struct CalculatedGoalPlan: Identifiable {
    let id: UUID
    let name: String
    let category: String
    let targetDate: Date
    let yearsFromNow: Int
    let baseAmount: Double
    let inflationAdjustedAmount: Double
    let monthlySIP: Double
    let assetAllocation: String
    let recommendedFunds: String
    let priority: Int
    var months: Int { yearsFromNow * 12 }
}

private enum GoalExecutionMode: String, CaseIterable, Identifiable {
    case sequential = "Sequential"
    case activateAll = "Activate All"
    var id: String { rawValue }
}

private func parseFinancialAmount(_ rawValue: String) -> Double? {
    let value = rawValue.lowercased()
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: ",", with: "")
        .replacingOccurrences(of: "₹", with: "")
        .replacingOccurrences(of: " ", with: "")
    guard !value.isEmpty else { return nil }
    let multipliers: [(suffixes: [String], value: Double)] = [
        (["crore", "crores", "cr"], 10_000_000),
        (["lakh", "lakhs", "lac", "lacs", "l"], 100_000),
        (["thousand", "k"], 1_000)
    ]
    for entry in multipliers {
        if let suffix = entry.suffixes.first(where: { value.hasSuffix($0) }) {
            let numberText = String(value.dropLast(suffix.count))
            guard let number = Double(numberText), number.isFinite, number >= 0 else { return nil }
            let amount = number * entry.value
            return amount.isFinite ? amount : nil
        }
    }
    guard let amount = Double(value), amount.isFinite, amount >= 0 else { return nil }
    return amount
}

struct PlanJourneyView: View {
    private let journeyPhases: [FinancialPlanningPhase] = [.today, .future, .timeline, .impact, .simulation, .strategy, .actions]
    @Environment(AppStateManager.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    var onComplete: (() -> Void)? = nil
    var goalContext: String? = nil

    @State private var editedEvent: FinancialPlanningEvent?
    @State private var editingGoalDraft: FinancialPlanningGoalDraft?
    @State private var throughYear: Int?
    @State private var contributionText = ""
    @State private var hasStartedPlanning = false
    @State private var customGoalName = ""
    @State private var targetAmountText: [UUID: String] = [:]
    @State private var showPlanGoalSelection = false
    @State private var editingAssumption: PlanningAssumption?
    @State private var selectedDetailedGoal: String? = nil
    @State private var showPlanSavedConfirmation = false
    // Inline customize state
    @State private var customizingGoalID: UUID? = nil
    @State private var customizeAmountText: String = ""
    @State private var customizeYears: Int = 3
    // Simulation sheet
    @State private var showSimulationSheet = false
    @State private var selectedSimulationPlan: Int = 1
    // Goal strategy mode & simulation/customization
    @State private var executionMode: GoalExecutionMode = .sequential
    @State private var simulatingGoal: CalculatedGoalPlan? = nil
    @State private var selectedGoalPlanOption: Int = 0
    @State private var customizingGoalCategory: CalculatedGoalPlan? = nil
    // Tracks which plan (0=SIP, 1=Loan/Debt, 2=StressTest) user activated per goal
    @State private var chosenPlanIndex: [UUID: Int] = [:]

    private var profile: AstraUserProfile? { appState.currentProfile }
    private var journey: FinancialPlanningJourney { profile?.planningJourney ?? FinancialPlanningJourney() }
    private var phase: FinancialPlanningPhase { journey.currentPhase == .priorities ? .future : journey.currentPhase }
    private var phaseIndex: Int { journeyPhases.firstIndex(of: phase) ?? 0 }
    private var phaseHeaderTitle: String {
        switch phase {
        case .today: "Financial snapshot"
        case .future: "Goals & events"
        case .timeline: "Timeline"
        case .impact: "Assumptions"
        case .priorities: "Priorities"
        case .simulation: "Simulation"
        case .strategy: "Financial strategy"
        case .actions: "Master plan"
        }
    }
    private var position: FinancialPositionSummary { FinancialPlanningEngine.currentPosition(profile: profile) }
    private var impacts: [FinancialEventImpact] { FinancialPlanningEngine.eventImpacts(profile: profile, journey: journey) }
    private var goals: [AstraGoal] { profile?.goals ?? [] }

    private var hasExistingJourney: Bool {
        !journey.goalDrafts.isEmpty
            || !journey.events.isEmpty
            || !journey.goalPriorityIDs.isEmpty
            || journey.currentPhase != .today
            || !goals.isEmpty
    }

    private var upcomingTimeline: [JourneyTimelineEntry] {
        let goalEntries = goals.map {
            JourneyTimelineEntry(
                id: $0.id,
                name: $0.goalName,
                detail: "Goal · \($0.targetAmount.toCurrency())",
                date: $0.targetDate,
                amount: $0.targetAmount,
                priority: 2,
                category: $0.goalName,
                isEvent: false
            )
        }
        let draftEntries = journey.goalDrafts.map {
            JourneyTimelineEntry(
                id: $0.id,
                name: $0.name,
                detail: "Planned goal · \($0.targetAmount?.toCurrency() ?? "Amount not set")",
                date: $0.targetDate,
                amount: $0.targetAmount,
                priority: $0.priority,
                category: $0.category,
                isEvent: false
            )
        }
        let draftNames = Set(journey.goalDrafts.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
        let uniqueGoals = goalEntries.filter { !draftNames.contains($0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) }
        let eventEntries = journey.events.map {
            JourneyTimelineEntry(
                id: $0.id,
                name: $0.name,
                detail: "\($0.status.rawValue) event",
                date: $0.targetDate,
                amount: $0.currentEstimatedCost,
                priority: $0.priority,
                category: "Event",
                isEvent: true
            )
        }
        return (uniqueGoals + draftEntries + eventEntries).sorted {
            ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture)
        }
    }

    private var priorityItems: [JourneyPriorityItem] {
        let drafts = journey.goalDrafts.map { draft in
            JourneyPriorityItem(
                id: draft.id,
                name: draft.name,
                detail: [draft.targetDate?.formatted(date: .abbreviated, time: .omitted), draft.targetAmount?.toCurrency()]
                    .compactMap { $0 }
                    .joined(separator: " · "),
                category: draft.category
            )
        }
        let draftNames = Set(journey.goalDrafts.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
        let savedGoals = goals.filter { !draftNames.contains($0.goalName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) }
            .map { JourneyPriorityItem(id: $0.id, name: $0.goalName, detail: "\($0.targetAmount.toCurrency()) · \($0.targetDate.formatted(date: .abbreviated, time: .omitted))", category: $0.goalName) }
        let items = drafts + savedGoals
        let positions = Dictionary(uniqueKeysWithValues: journey.goalPriorityIDs.enumerated().map { ($1, $0) })
        return items.enumerated().sorted { left, right in
            let leftPosition = positions[left.element.id] ?? (journey.goalPriorityIDs.count + left.offset)
            let rightPosition = positions[right.element.id] ?? (journey.goalPriorityIDs.count + right.offset)
            return leftPosition < rightPosition
        }.map(\.element)
    }

    private var orderedGoalDrafts: [FinancialPlanningGoalDraft] {
        journey.goalDrafts.enumerated().sorted { left, right in
            let leftOrder = journey.goalPriorityIDs.firstIndex(of: left.element.id) ?? (journey.goalPriorityIDs.count + left.offset)
            let rightOrder = journey.goalPriorityIDs.firstIndex(of: right.element.id) ?? (journey.goalPriorityIDs.count + right.offset)
            return leftOrder < rightOrder
        }.map(\.element)
    }

    // MARK: - Multi-Goal Mathematical Plan Calculations
    private var calculatedGoalPlans: [CalculatedGoalPlan] {
        let inflation = journey.assumptions.inflationRate ?? 0.06
        let generalReturn = journey.assumptions.investmentReturnRate ?? 0.11

        return orderedGoalDrafts.compactMap { draft in
            guard let targetDate = draft.targetDate, let baseCost = draft.targetAmount else { return nil }
            let years = max(1, Calendar.current.dateComponents([.year], from: Date(), to: targetDate).year ?? 1)
            let futureTarget = baseCost * pow(1 + inflation, Double(years))

            let returnRate: Double = {
                if years < 3 { return 0.07 }
                else if years < 7 { return 0.10 }
                else { return generalReturn }
            }()

            let monthlyRate = returnRate / 12.0
            let months = Double(years * 12)
            let sip: Double = {
                guard monthlyRate > 0 else { return futureTarget / months }
                return (futureTarget * monthlyRate) / (pow(1 + monthlyRate, months) - 1)
            }()

            let allocation: String = {
                if years < 3 { return "100% Debt & Arbitrage" }
                else if years < 7 { return "60% Equity / 40% Balanced & Hybrid" }
                else { return "80% Equity / 20% Debt & Gold" }
            }()

            let funds: String = {
                if years < 3 { return "Liquid & Ultra-Short Term Debt, Arbitrage Funds" }
                else if years < 7 { return "Balanced Advantage & Multi-Asset Hybrid Funds" }
                else { return "Flexi-Cap & Large & Mid-Cap Equity Mutual Funds" }
            }()

            return CalculatedGoalPlan(
                id: draft.id,
                name: draft.name,
                category: draft.category,
                targetDate: targetDate,
                yearsFromNow: years,
                baseAmount: baseCost,
                inflationAdjustedAmount: futureTarget,
                monthlySIP: sip,
                assetAllocation: allocation,
                recommendedFunds: funds,
                priority: draft.priority
            )
        }
    }

    private var totalMonthlySIPNeeded: Double {
        calculatedGoalPlans.reduce(0) { $0 + $1.monthlySIP }
    }

    private var totalWealthProjected: Double {
        calculatedGoalPlans.reduce(0) { $0 + $1.inflationAdjustedAmount }
    }

    private var capacityBreakdown: FinancialCapacityBreakdown {
        FinancialCapacityEngine.evaluateCapacity(profile: profile)
    }

    private var availableMonthlyCapacity: Double {
        if capacityBreakdown.availableMonthlyPlanningCapacity > 0 {
            return capacityBreakdown.availableMonthlyPlanningCapacity
        }
        return position.monthlySurplus ?? 43_000
    }

    private var multiGoalOptimization: MultiGoalOptimizationResult {
        MultiGoalOptimizer.optimize(
            goals: orderedGoalDrafts,
            availableMonthlyCapacity: availableMonthlyCapacity,
            mode: executionMode == .sequential ? "Sequential" : "Activate All"
        )
    }

    // Priority-waterfall: how much surplus each goal receives
    private struct GoalSurplusAllocation {
        let id: UUID
        let allocated: Double   // actually funded from surplus
        let deficit: Double     // shortfall needing step-up SIP or extra saving
        let isFocusGoal: Bool   // first goal that doesn't have full coverage
    }

    private var surplusAllocationByGoal: [GoalSurplusAllocation] {
        let result = multiGoalOptimization
        return calculatedGoalPlans.map { plan in
            let alloc = result.allocations.first(where: { $0.id == plan.id })
            let allocated = alloc?.allocatedMonthlyCapacity ?? 0
            let deficit = alloc?.monthlyDeficit ?? 0
            let isFocus = calculatedGoalPlans.first?.id == plan.id
            return GoalSurplusAllocation(id: plan.id, allocated: allocated, deficit: deficit, isFocusGoal: isFocus)
        }
    }

    private func makeInputModel(for plan: CalculatedGoalPlan) -> InvestmentPlanInputModel {
        InvestmentPlanInputModel(
            investmentType: "Monthly SIP",
            amount: String(format: "%.0f", plan.monthlySIP),
            liquidity: plan.yearsFromNow < 3 ? "High" : (plan.yearsFromNow < 7 ? "Medium" : "Low"),
            riskType: plan.yearsFromNow < 3 ? "Low" : (plan.yearsFromNow < 7 ? "Moderate" : "High"),
            timePeriod: String(plan.yearsFromNow),
            scheduleInvestmentDate: Date(),
            scheduleSIPDate: Date(),
            purposeOfInvestment: plan.name,
            targetAmount: String(format: "%.0f", plan.inflationAdjustedAmount),
            savedAmount: "0",
            hasEmergencyFund: true,
            monthlyIncome: availableMonthlyCapacity,
            existingEMIs: 0
        )
    }

    private struct EffectiveGoalAllocation {
        let id: UUID
        let allocatedMonthlyCapacity: Double
        let monthlyCommitment: Double
        let isLoan: Bool
        let isDualTrackUnlocked: Bool
        let statusTitle: String
        let statusDescription: String
    }

    private var effectiveAllocations: [UUID: EffectiveGoalAllocation] {
        var allocations: [UUID: EffectiveGoalAllocation] = [:]
        var remainingCapacity = availableMonthlyCapacity
        var hasUnlockedDualTrack = false
        var unlockingGoalName: String? = nil

        for (index, plan) in calculatedGoalPlans.enumerated() {
            let chosenIdx = chosenPlanIndex[plan.id]
            let isFirst = index == 0

            if executionMode == .sequential {
                if let idx = chosenIdx, idx == 1 { // Plan 2: Traditional Loan
                    let input = makeInputModel(for: plan)
                    let full = InvestmentPlannerEngine.generateFullPlan(input: input, profile: profile)
                    let emi = full.plan2?.monthlyEMI ?? plan.monthlySIP
                    let allocated = min(remainingCapacity, emi)
                    remainingCapacity = max(0, remainingCapacity - allocated)
                    hasUnlockedDualTrack = remainingCapacity > 0
                    unlockingGoalName = plan.name

                    allocations[plan.id] = EffectiveGoalAllocation(
                        id: plan.id,
                        allocatedMonthlyCapacity: allocated,
                        monthlyCommitment: emi,
                        isLoan: true,
                        isDualTrackUnlocked: false,
                        statusTitle: "Plan 2: Loan Active (\(allocated.toCurrency())/mo EMI)",
                        statusDescription: remainingCapacity > 0
                            ? "Residual surplus of \(remainingCapacity.toCurrency())/mo cascades directly into the next priority goal!"
                            : "100% surplus servicing loan EMI."
                    )
                } else if let idx = chosenIdx, idx == 2 { // Plan 3: Loan Stress-Test
                    let input = makeInputModel(for: plan)
                    let full = InvestmentPlannerEngine.generateFullPlan(input: input, profile: profile)
                    let emi = full.plan3?.monthlyEMI ?? plan.monthlySIP
                    let allocated = min(remainingCapacity, emi)
                    remainingCapacity = max(0, remainingCapacity - allocated)
                    hasUnlockedDualTrack = remainingCapacity > 0
                    unlockingGoalName = plan.name

                    allocations[plan.id] = EffectiveGoalAllocation(
                        id: plan.id,
                        allocatedMonthlyCapacity: allocated,
                        monthlyCommitment: emi,
                        isLoan: true,
                        isDualTrackUnlocked: false,
                        statusTitle: "Plan 3: Stress-Test Active (\(allocated.toCurrency())/mo EMI)",
                        statusDescription: remainingCapacity > 0
                            ? "Residual surplus of \(remainingCapacity.toCurrency())/mo cascades directly into the next priority goal!"
                            : "100% surplus servicing loan stress-test."
                    )
                } else { // Plan 1 or Default SIP
                    let needed = plan.monthlySIP
                    if isFirst {
                        let allocated = min(remainingCapacity, needed)
                        remainingCapacity = max(0, remainingCapacity - allocated)
                        allocations[plan.id] = EffectiveGoalAllocation(
                            id: plan.id,
                            allocatedMonthlyCapacity: allocated,
                            monthlyCommitment: needed,
                            isLoan: false,
                            isDualTrackUnlocked: false,
                            statusTitle: "Priority First Focus: \(allocated.toCurrency())/mo allocated (100% focused)",
                            statusDescription: "Focuses all available savings until goal completion."
                        )
                    } else if hasUnlockedDualTrack && remainingCapacity > 0 {
                        // Cascaded surplus unlocked from prior loan!
                        let allocated = min(remainingCapacity, needed)
                        remainingCapacity = max(0, remainingCapacity - allocated)
                        allocations[plan.id] = EffectiveGoalAllocation(
                            id: plan.id,
                            allocatedMonthlyCapacity: allocated,
                            monthlyCommitment: needed,
                            isLoan: false,
                            isDualTrackUnlocked: true,
                            statusTitle: "⚡ Dual-Track Activated: \(allocated.toCurrency())/mo invested concurrently",
                            statusDescription: "Unlocked by loan financing on \(unlockingGoalName ?? "Goal 1"). Starts investing immediately!"
                        )
                    } else {
                        // Regular queue
                        let priorGoal = calculatedGoalPlans.first
                        allocations[plan.id] = EffectiveGoalAllocation(
                            id: plan.id,
                            allocatedMonthlyCapacity: 0,
                            monthlyCommitment: needed,
                            isLoan: false,
                            isDualTrackUnlocked: false,
                            statusTitle: "Sequential Queue: Starts after \(priorGoal?.name ?? "Goal 1") completes in \(priorGoal?.targetDate.formatted(date: .abbreviated, time: .omitted) ?? "Year 2")",
                            statusDescription: "Subsequent goal in queue."
                        )
                    }
                }
            } else {
                // Activate All mode
                let baseAlloc = multiGoalOptimization.allocations.first(where: { $0.id == plan.id })
                let allocated = baseAlloc?.allocatedMonthlyCapacity ?? 0
                let deficit = baseAlloc?.monthlyDeficit ?? 0
                allocations[plan.id] = EffectiveGoalAllocation(
                    id: plan.id,
                    allocatedMonthlyCapacity: allocated,
                    monthlyCommitment: plan.monthlySIP,
                    isLoan: false,
                    isDualTrackUnlocked: false,
                    statusTitle: "Every Month Allocation: \(allocated.toCurrency()) / mo (Active Concurrently)",
                    statusDescription: deficit > 0 ? "Monthly Gap: \(deficit.toCurrency()) / mo" : "Fully funded"
                )
            }
        }

        return allocations
    }

    // Optimistic early-completion dates (14% CAGR scenario)
    private var optimisticCompletionMonths: [UUID: Int] {
        var result: [UUID: Int] = [:]
        for plan in calculatedGoalPlans {
            let r = 0.14 / 12.0
            let months = plan.months
            guard r > 0 else { result[plan.id] = months; continue }
            // Solve: SIP * ((1+r)^n - 1)/r = target
            // n = log(1 + target*r/SIP) / log(1+r)
            let numerator = 1 + (plan.inflationAdjustedAmount * r / plan.monthlySIP)
            guard numerator > 0 else { result[plan.id] = months; continue }
            let n = log(numerator) / log(1 + r)
            result[plan.id] = max(1, Int(n.rounded(.up)))
        }
        return result
    }

    var body: some View {
        Group {
            if hasStartedPlanning {
                journeySteps
            } else {
                journeyIntroduction
            }
        }
        .navigationTitle(hasStartedPlanning ? phaseHeaderTitle : "Financial Journey")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if hasStartedPlanning, phaseIndex > 0 {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            advance(to: journeyPhases[phaseIndex - 1])
                        }
                    } else if hasStartedPlanning {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            hasStartedPlanning = false
                        }
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 40, height: 40)
                }
                .accessibilityLabel(hasStartedPlanning ? "Go back one journey step" : "Back to Planner")
                .buttonStyle(.plain)
            }

            if hasStartedPlanning {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(phaseIndex + 1) of \(journeyPhases.count)")
                        .font(.subheadline.weight(.medium).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationDestination(isPresented: $showPlanGoalSelection) {
            let firstGoal = orderedGoalDrafts.first
            GoalSelectionView(
                reviewJourneyFirst: false,
                initialGoal: firstGoal.map { $0.category == "Custom" ? "Custom Goal" : $0.category },
                initialGoalTitle: firstGoal?.name
            )
        }
        .sheet(item: $editedEvent) { event in
            PlanningEventEditor(event: event, goals: goals) { updatedEvent in
                var updatedJourney = journey
                if let index = updatedJourney.events.firstIndex(where: { $0.id == updatedEvent.id }) {
                    updatedJourney.events[index] = updatedEvent
                } else {
                    updatedJourney.events.append(updatedEvent)
                }
                appState.updateFinancialPlanningJourney(updatedJourney)
            }
        }
        .sheet(item: $editingGoalDraft) { draft in
            GoalDraftQuickEditor(draft: draft) { updatedDraft in
                updateGoalDraft(updatedDraft.id) { current in
                    current = updatedDraft
                }
            }
        }
        .sheet(item: $editingAssumption) { assumption in
            AssumptionValueEditor(
                assumption: assumption,
                value: journey.assumptions[keyPath: assumption.keyPath],
                onSave: { value in
                    var updated = journey
                    updated.assumptions[keyPath: assumption.keyPath] = value
                    updated.assumptions.enteredAt = Date()
                    updated.assumptions.version += 1
                    appState.updateFinancialPlanningJourney(updated)
                }
            )
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPlanSavedConfirmation) {
            masterPlanCelebrationSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $simulatingGoal) { plan in
            goalSpecificSimulationSheet(plan: plan)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $customizingGoalCategory) { plan in
            goalQuestionnaireSheet(plan: plan)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: Binding<CalculatedGoalPlan?>(
            get: { activeCustomizingPlan },
            set: { customizingGoalID = $0?.id }
        )) { plan in
            inlineGoalCustomizeSheet(plan: plan)
                .presentationDetents([.height(520)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSimulationSheet) {
            goalSimulationSheet
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: profile?.planningJourney?.monthlyInvestmentWhatIf) { _, amount in
            contributionText = amount.map { String($0) } ?? ""
        }
        .onAppear {
            if hasExistingJourney {
                hasStartedPlanning = true
            }
            contributionText = journey.monthlyInvestmentWhatIf.map { String($0) } ?? ""
            ensurePresetsForAllDrafts()
        }
    }

    // MARK: - Journey Stepper View
    private var journeySteps: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                phaseContent

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .frame(maxWidth: 600, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .id(phase)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomFloatingBar
        }
    }

    // MARK: - Bottom Floating Action Bar
    private var bottomFloatingBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.3)
            HStack(spacing: 12) {
                if phaseIndex > 0 {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            advance(to: journeyPhases[phaseIndex - 1])
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 52)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if phase == .actions {
                        saveAndActivateCompletePlan()
                    } else {
                        let next = journeyPhases[min(journeyPhases.count - 1, phaseIndex + 1)]
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            advance(to: next)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(phase == .actions ? "Save & Activate Complete Plan" : phase == .today ? "Continue to Goals" : "Continue")
                            .font(.headline.weight(.semibold))
                        if phase == .actions {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .frame(height: 52)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .background(AppTheme.accentGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Journey Introduction Screen
    private var journeyIntroduction: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                if hasExistingJourney {
                    savedJourneyOverview
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(LinearGradient(colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(height: 110)
                        HStack(spacing: 16) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 64, height: 64)
                                .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .shadow(color: Color.blue.opacity(0.2), radius: 8, x: 0, y: 4)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("AstraFi Financial Journey")
                                    .font(.title3.weight(.bold))
                                Text("A comprehensive personal roadmap built for you.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Plan your journey")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("Let's understand your life before we plan your money.")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                        Text("We'll assess your current position, map important life events and goals, and stress-test your wealth capacity.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        journeyOutlineRow("01", "Where you stand today", "heart.text.square.fill", .green)
                        journeyOutlineRow("02", "What you want to achieve", "target", .blue)
                        journeyOutlineRow("03", "Build your future timeline", "calendar", .purple)
                        journeyOutlineRow("04", "Future financial assumptions", "slider.horizontal.3", .orange)
                        journeyOutlineRow("05", "Stress test your plan", "chart.line.uptrend.xyaxis", .pink)
                        journeyOutlineRow("06", "Build your financial strategy", "chart.pie.fill", .indigo)
                        journeyOutlineRow("07", "Your personalized action plan", "checklist", .teal)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                    }

                    Button {
                        var updated = journey
                        updated.currentPhase = .today
                        appState.updateFinancialPlanningJourney(updated)
                        withAnimation(.spring(response: 0.35)) {
                            hasStartedPlanning = true
                        }
                    } label: {
                        HStack {
                            Text("Start Planning")
                                .font(.headline.weight(.semibold))
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .foregroundStyle(.white)
                        .background(AppTheme.accentGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: Color.blue.opacity(0.35), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 28)
            .frame(maxWidth: 600, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private func journeyOutlineRow(_ number: String, _ title: String, _ icon: String, _ tint: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(tint.opacity(0.12)).frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            Spacer()
            Text(number)
                .font(.caption2.weight(.bold).monospacedDigit())
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Saved Journey Overview (Resume Card)
    private var savedJourneyOverview: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your Financial Roadmap")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Review your active milestones, monthly surplus, and planning timeline.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Financial Snapshot Banner
            HStack(spacing: 10) {
                metricSummaryBox(title: "Income", amount: position.monthlyIncome, tint: .green)
                metricSummaryBox(title: "Expenses", amount: position.monthlyExpenses, tint: .orange)
                metricSummaryBox(title: "Surplus", amount: position.monthlySurplus, tint: .blue)
            }

            journeySection("Active Goals & Milestones", icon: "target", tint: .blue) {
                if orderedGoalDrafts.isEmpty && goals.isEmpty {
                    Text("No goals mapped yet. Tap below to begin planning.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 8) {
                        ForEach(Array(orderedGoalDrafts.enumerated()), id: \.element.id) { index, goal in
                            HStack(spacing: 10) {
                                Text("\(index + 1)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.blue, in: Circle())
                                Text(goal.name)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(goal.targetAmount?.toCurrency() ?? "Amount not set")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(10)
                            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }

            VStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.35)) {
                        hasStartedPlanning = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Resume / Edit Journey")
                    }
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundStyle(.white)
                    .background(AppTheme.accentGradient, in: RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)

                Button {
                    showPlanGoalSelection = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Plan a Specific Goal Now")
                    }
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundStyle(Color.accentColor)
                    .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func metricSummaryBox(title: String, amount: Double?, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            Text(amount?.toCurrency(compact: true) ?? "—")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Phase Content Switcher
    @ViewBuilder private var phaseContent: some View {
        switch phase {
        case .today: todayContent
        case .future: futureContent
        case .timeline: timelineContent
        case .impact: impactContent
        case .priorities: prioritiesContent
        case .simulation: simulationContent
        case .strategy: strategyContent
        case .actions: actionsContent
        }
    }

    // MARK: - STEP 1: Today / Where you stand today
    private var todayContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Health Score Hero Card
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppTheme.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    }

                HStack(spacing: 16) {
                    let score = profile?.monthlyHealthAssessments.max(by: { $0.date < $1.date })?.score ?? 78
                    ZStack {
                        Circle()
                            .stroke(Color.green.opacity(0.2), lineWidth: 8)
                            .frame(width: 68, height: 68)
                        Circle()
                            .trim(from: 0, to: CGFloat(score) / 100.0)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 68, height: 68)
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 0) {
                            Text("\(score)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            Text("/100")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Financial Health Baseline")
                            .font(.headline.weight(.bold))
                        if let months = position.emergencyMonths {
                            Text("Emergency Buffer: \(months.formatted(.number.precision(.fractionLength(1)))) months covered")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Emergency reserve target: 6 months of expenses")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(16)
            }

            // Monthly Cash Flow Card
            journeySection("Monthly Cash Flow", icon: "banknote.fill", tint: .green) {
                HStack(spacing: 8) {
                    cashFlowCard("Income", position.monthlyIncome, .green)
                    cashFlowCard("Expenses", position.monthlyExpenses, .orange)
                    cashFlowCard("Surplus", position.monthlySurplus, .blue)
                }

                if let rate = position.savingRate {
                    HStack {
                        Text("Current Savings Rate")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(rate.formatted(.percent.precision(.fractionLength(0))))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(rate >= 0.2 ? Color.green : Color.orange)
                    }
                    .padding(.top, 4)
                }
            }

            // Key Financial Pillars
            journeySection("Financial Position Summary", icon: "chart.bar.fill", tint: .purple) {
                positionRow("Investments recorded", value: position.investments?.toCurrency())
                positionRow("Monthly investment (SIP)", value: position.monthlyInvestmentContribution?.toCurrency())
                positionRow("Total outstanding loans", value: position.debt?.toCurrency())
                positionRow("Monthly EMI payments", value: position.monthlyDebtPayments?.toCurrency())
                positionRow("Insurance sum assured", value: position.insuranceCoverage?.toCurrency())
            }

            // Quick profile completion
            journeySection("Update Stored Profile", icon: "person.crop.circle.badge.checkmark", tint: .blue) {
                Text("Your journey uses verified details from your AstraFi profile.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(spacing: 6) {
                    profileLinkRow("Personal & Demographics", destination: AnyView(BasicInformationDetailView()), isDone: (profile?.basicDetails.age ?? 0) > 0)
                    profileLinkRow("Income & Monthly Expenses", destination: AnyView(FinancialProfileDetailView()), isDone: (position.monthlyIncome ?? 0) > 0)
                    profileLinkRow("Portfolio & Investments", destination: AnyView(FullInvestmentListView()), isDone: position.investments != nil)
                    profileLinkRow("Loans & Liabilities", destination: AnyView(LoanTrackerView()), isDone: position.debt != nil)
                    profileLinkRow("Insurance Policies", destination: AnyView(InsuranceListView()), isDone: position.insuranceCoverage != nil)
                }
            }
        }
    }

    private func cashFlowCard(_ title: String, _ amount: Double?, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            Text(amount?.toCurrency(compact: true) ?? "—")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
    }

    private func profileLinkRow(_ title: String, destination: AnyView, isDone: Bool) -> some View {
        NavigationLink {
            destination
        } label: {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Spacer()
                Text(isDone ? "✓ Ready" : "＋ Add")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(isDone ? Color.green : Color.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((isDone ? Color.green : Color.orange).opacity(0.12), in: Capsule())
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - STEP 2: Future / What do you want to achieve?
    private var futureContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Profile Mini-Capsule Bar (compact & neat)
            HStack(spacing: 8) {
                profilePill("person.fill", "\(profile?.basicDetails.age ?? 23) yrs")
                profilePill("heart.fill", profile?.basicDetails.maritalStatus.rawValue.capitalized ?? "Single")
                profilePill("person.2.fill", "\(profile?.basicDetails.adultDependents ?? 0) Adults")
                profilePill("figure.and.child.holdinghands", "\(profile?.basicDetails.childDependents ?? 0) Kids")
            }

            // Goals Selection
            journeySection("Select Your Goals", icon: "target", tint: .blue) {
                Text("Select goals to map. AstraFi automatically assigns intelligent default target dates and budgets according to priority.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                goalSelectionGrid

                // Custom Goal Field
                HStack(spacing: 8) {
                    TextField("＋ Add custom goal (e.g. Dream Vacation)", text: $customGoalName)
                        .font(.subheadline)
                        .padding(10)
                        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                        .submitLabel(.done)
                        .onSubmit(addCustomGoal)

                    Button("Add") {
                        addCustomGoal()
                    }
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(customGoalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.2) : Color.blue, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                    .disabled(customGoalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.top, 4)
            }

            // Selected Goals Configurator (Interactive cards)
            if !journey.goalDrafts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Configure Goals & Parameters")
                            .font(.headline.weight(.bold))
                        Spacer()
                        Text("Tap to edit defaults")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(journey.goalDrafts) { draft in
                        goalConfigurationCard(draft)
                    }
                }
            }

            // Life Events Section
            journeySection("Life Events to Explore", icon: "sparkles", tint: .purple) {
                Text("Events alter future cash flow, income, or emergency needs.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                lifeEventSuggestions

                if !journey.events.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(journey.events) { event in
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.subheadline)
                                    .foregroundStyle(.purple)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.name).font(.subheadline.weight(.semibold))
                                    Text(event.targetDate?.formatted(date: .abbreviated, time: .omitted) ?? "Date not specified")
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Edit") { editedEvent = event }
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.blue)
                                Button {
                                    var updated = journey
                                    updated.events.removeAll { $0.id == event.id }
                                    appState.updateFinancialPlanningJourney(updated)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                                .padding(.leading, 6)
                            }
                            .padding(10)
                            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }

                Button { editedEvent = FinancialPlanningEvent(name: "") } label: {
                    Label("Add custom life event", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.top, 4)
            }

            // Priority reordering section
            if !priorityItems.isEmpty {
                journeySection("Goal Priority Order", icon: "arrow.up.arrow.down", tint: .orange) {
                    prioritiesContent
                }
            }
        }
    }

    private func profilePill(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.accentColor)
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.09), in: Capsule())
    }

    private var goalSelectionGrid: some View {
        let options: [(name: String, icon: String, color: Color)] = [
            ("Marriage", "heart.fill", .pink),
            ("Children", "figure.2.and.child.holdinghands", .orange),
            ("Build Wealth", "chart.line.uptrend.xyaxis", .indigo),
            ("Education", "book.fill", .blue),
            ("Home", "house.fill", .green),
            ("Vehicle", "car.fill", .orange),
            ("Travel", "airplane", .cyan),
            ("Retirement", "leaf.fill", .purple),
            ("Family", "figure.2", .teal),
            ("Business Fund", "briefcase.fill", .teal)
        ]

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
            ForEach(options, id: \.name) { opt in
                let isSelected = journey.goalDrafts.contains { $0.category == opt.name }
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    toggleGoalDraft(category: opt.name, name: opt.name)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : opt.icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isSelected ? opt.color : opt.color.opacity(0.8))
                        Text(opt.name)
                            .font(.subheadline.weight(isSelected ? .bold : .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(isSelected ? opt.color.opacity(0.12) : Color(UIColor.secondarySystemGroupedBackground))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(isSelected ? opt.color.opacity(0.4) : Color.clear, lineWidth: 1.5)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func goalConfigurationCard(_ draft: FinancialPlanningGoalDraft) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: goalIcon(for: draft.category))
                        .foregroundStyle(goalTint(for: draft.category))
                    Text(draft.name)
                        .font(.headline.weight(.bold))
                }
                Spacer()

                Menu {
                    Button("High Priority 🔥") { updateGoalDraft(draft.id) { $0.priority = 1 } }
                    Button("Medium Priority ⚡️") { updateGoalDraft(draft.id) { $0.priority = 2 } }
                    Button("Low Priority 🌿") { updateGoalDraft(draft.id) { $0.priority = 3 } }
                    Divider()
                    Button("Remove Goal", role: .destructive) { removeGoalDraft(draft.id) }
                } label: {
                    Text(priorityLabel(draft.priority))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(priorityColor(draft.priority))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(priorityColor(draft.priority).opacity(0.12), in: Capsule())
                }

                Button {
                    removeGoalDraft(draft.id)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.tertiary)
                }
            }

            // Target Amount & Preset Suggestions
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Target Amount")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let amt = draft.targetAmount {
                        Text(amt.toCurrency())
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.accentColor)
                    }
                }

                HStack(spacing: 6) {
                    amountPresetChip("₹10L", 1_000_000, draft.id)
                    amountPresetChip("₹25L", 2_500_000, draft.id)
                    amountPresetChip("₹50L", 5_000_000, draft.id)
                    amountPresetChip("₹1Cr", 10_000_000, draft.id)
                }

                TextField("Or enter custom amount · e.g. 15L or 2Cr", text: Binding(
                    get: { targetAmountText[draft.id] ?? draft.targetAmount.map { String(format: "%.0f", $0) } ?? "" },
                    set: { val in
                        targetAmountText[draft.id] = val
                        updateGoalDraft(draft.id) { $0.targetAmount = parseFinancialAmount(val) }
                    }
                ))
                .keyboardType(.decimalPad)
                .font(.subheadline)
                .padding(10)
                .background(Color(UIColor.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
            }

            // Target Date Picker
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Target Timeline")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let targetDate = draft.targetDate {
                        let years = max(1, Calendar.current.dateComponents([.year], from: Date(), to: targetDate).year ?? 1)
                        Text("\(years) yrs from now (\(targetDate.formatted(date: .abbreviated, time: .omitted)))")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.accentColor)
                    }
                }

                DatePicker("Target Date", selection: Binding(
                    get: { draft.targetDate ?? Calendar.current.date(byAdding: .year, value: 3, to: Date())! },
                    set: { date in updateGoalDraft(draft.id) { $0.targetDate = date } }
                ), in: Calendar.current.startOfDay(for: Date())..., displayedComponents: .date)
                .font(.caption)
                .datePickerStyle(.compact)
            }
        }
        .padding(14)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func amountPresetChip(_ label: String, _ value: Double, _ goalID: UUID) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            updateGoalDraft(goalID) { $0.targetAmount = value }
            targetAmountText[goalID] = String(format: "%.0f", value)
        } label: {
            Text(label)
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.accentColor.opacity(0.09), in: Capsule())
                .foregroundStyle(Color.accentColor)
        }
    }

    private var lifeEventSuggestions: some View {
        let suggestions = ["Marriage", "Child Born", "School / College", "Home Purchase", "Career Pivot", "Business Launch", "Medical Fund", "Retirement"]
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { name in
                    Button {
                        guard !journey.events.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) else { return }
                        editedEvent = FinancialPlanningEvent(name: name, status: .planned)
                    } label: {
                        Text("＋ \(name)")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(Color.purple.opacity(0.1), in: Capsule())
                            .foregroundStyle(.purple)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - STEP 3: Timeline / Build your future timeline (Visual Roadmap)
    private var timelineContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if upcomingTimeline.isEmpty {
                ContentUnavailableView(
                    "No timeline items yet",
                    systemImage: "calendar.badge.plus",
                    description: Text("Go back to Step 2 to select goals or add life events with target dates.")
                )
                .frame(minHeight: 220)
            } else {
                // Interactive Visual Roadmap
                VStack(spacing: 0) {
                    ForEach(Array(upcomingTimeline.enumerated()), id: \.element.id) { index, entry in
                        HStack(alignment: .top, spacing: 14) {
                            // Timeline track with connected vertical node
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(goalTint(for: entry.category))
                                    .frame(width: 14, height: 14)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    .shadow(color: goalTint(for: entry.category).opacity(0.4), radius: 3)

                                if index < upcomingTimeline.count - 1 {
                                    Rectangle()
                                        .fill(LinearGradient(
                                            colors: [goalTint(for: entry.category).opacity(0.5), Color.primary.opacity(0.1)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ))
                                        .frame(width: 2)
                                        .frame(maxHeight: .infinity)
                                }
                            }
                            .frame(width: 16)

                            // Milestone Card
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    // Calendar date tile
                                    if let date = entry.date {
                                        let years = max(1, Calendar.current.dateComponents([.year], from: Date(), to: date).year ?? 1)
                                        VStack(spacing: 2) {
                                            Text(date.formatted(.dateTime.month(.abbreviated)).uppercased())
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(goalTint(for: entry.category))
                                            Text(date.formatted(.dateTime.year()))
                                                .font(.system(size: 13, weight: .bold).monospacedDigit())
                                                .foregroundStyle(.primary)
                                            Text("+\(years)y")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundStyle(.secondary)
                                        }
                                        .frame(width: 48, height: 50)
                                        .background(goalTint(for: entry.category).opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                                    } else {
                                        Button {
                                            openQuickDateEditor(for: entry)
                                        } label: {
                                            VStack(spacing: 2) {
                                                Image(systemName: "calendar.badge.plus")
                                                    .font(.system(size: 14, weight: .bold))
                                                Text("Set Date")
                                                    .font(.system(size: 9, weight: .bold))
                                            }
                                            .foregroundStyle(.orange)
                                            .frame(width: 48, height: 50)
                                            .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 6) {
                                            Text(entry.name)
                                                .font(.headline.weight(.bold))
                                                .foregroundStyle(.primary)

                                            if entry.isEvent {
                                                Text("EVENT")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundStyle(.purple)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.purple.opacity(0.12), in: Capsule())
                                            }
                                        }

                                        if let amt = entry.amount {
                                            Text("Target: \(amt.toCurrency())")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(Color.accentColor)
                                        } else {
                                            Text("Target amount not set")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    // Priority Pill
                                    Text(priorityLabel(entry.priority))
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(priorityColor(entry.priority))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(priorityColor(entry.priority).opacity(0.1), in: Capsule())
                                }

                                if entry.date == nil {
                                    Button {
                                        openQuickDateEditor(for: entry)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "clock")
                                            Text("Set target date to unlock stress-testing simulation")
                                        }
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.orange)
                                    }
                                }
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                            }
                            .padding(.bottom, 12)
                        }
                    }
                }
            }

            Button {
                editedEvent = FinancialPlanningEvent(name: "")
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add a Life Milestone / Event")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }

    private func openQuickDateEditor(for entry: JourneyTimelineEntry) {
        if let draft = journey.goalDrafts.first(where: { $0.id == entry.id }) {
            editingGoalDraft = draft
        } else if let event = journey.events.first(where: { $0.id == entry.id }) {
            editedEvent = event
        }
    }

    // MARK: - STEP 4: Impact / Assumptions & Future Impact
    private var impactContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Explanation callout
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Macro Financial Assumptions")
                        .font(.subheadline.weight(.bold))
                    Text("Transparent rates used to estimate inflation, compounding growth, and future target capital.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))

            // Assumptions Cards Grid
            VStack(spacing: 10) {
                ForEach(PlanningAssumption.allCases) { assumption in
                    assumptionInteractiveCard(assumption)
                }
            }

            // Events & Goals Impact
            if !impacts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Inflation Impact on Your Goals")
                        .font(.headline.weight(.bold))

                    ForEach(impacts) { impact in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(impact.name)
                                    .font(.headline.weight(.semibold))
                                Spacer()
                                if let date = impact.date {
                                    Text(date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.secondary)
                                }
                            }

                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Cost Today")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(impact.currentCost?.toCurrency() ?? "Not set")
                                        .font(.subheadline.weight(.bold))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Image(systemName: "arrow.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Future Cost (Adjusted)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(impact.futureCost?.toCurrency() ?? "Set inflation")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(Color.purple)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(10)
                            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

                            if let monthly = impact.monthlyContributionWithoutGrowth {
                                HStack {
                                    Text("Monthly savings needed (without growth):")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(monthly.toCurrency())
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .padding(14)
                        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                        }
                    }
                }
            }
        }
    }

    private func assumptionInteractiveCard(_ assumption: PlanningAssumption) -> some View {
        Button {
            editingAssumption = assumption
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(assumption.tint.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: assumption.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(assumption.tint)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(assumption.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(assumption.detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    let rate = journey.assumptions[keyPath: assumption.keyPath]
                    Text(rate.map { "\(( $0 * 100).formatted(.number.precision(.fractionLength(0...2))))%" } ?? "Set Rate")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(rate == nil ? Color.orange : Color.accentColor)

                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.08), in: Capsule())
            }
            .padding(14)
            .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - STEP 5: Simulation / Stress test your plan
    private var simulationContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Dual Goal Concurrency Box
            journeySection("Dual Goal Concurrency Check", icon: "arrow.triangle.merge", tint: .blue) {
                Text("Assesses whether multiple goals maturing near each other can be funded comfortably with your surplus.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                let savedGoalNeeds = goals.filter { $0.targetDate > Date() }.map { goal in
                    JourneyGoalNeed(id: goal.id, name: goal.goalName, date: goal.targetDate, monthlyNeed: estimatedMonthlyNeed(for: goal))
                }
                let savedNames = Set(goals.map { $0.goalName.lowercased() })
                let draftGoalNeeds = journey.goalDrafts.compactMap { draft -> JourneyGoalNeed? in
                    guard !savedNames.contains(draft.name.lowercased()), let date = draft.targetDate, date > Date(), let amount = draft.targetAmount else { return nil }
                    let months = max(1, Calendar.current.dateComponents([.month], from: Date(), to: date).month ?? 1)
                    return JourneyGoalNeed(id: draft.id, name: draft.name, date: date, monthlyNeed: max(0, amount) / Double(months))
                }
                let activeGoals = (savedGoalNeeds + draftGoalNeeds).sorted { $0.date < $1.date }

                if activeGoals.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.title2)
                            .foregroundStyle(.orange)
                        Text("Add dated goals with target amounts to compare them.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                } else {
                    VStack(spacing: 8) {
                        ForEach(Array(activeGoals.prefix(2)), id: \.id) { goal in
                            HStack {
                                Text("\(goal.name) (\(goal.date.formatted(date: .abbreviated, time: .omitted)))")
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text("\(goal.monthlyNeed.toCurrency()) / mo")
                                    .font(.subheadline.weight(.semibold).monospacedDigit())
                            }
                        }
                        Divider()
                        let combined = activeGoals.prefix(2).reduce(0) { $0 + $1.monthlyNeed }
                        HStack {
                            Text("Combined Monthly Target")
                                .font(.subheadline.weight(.bold))
                            Spacer()
                            Text("\(combined.toCurrency()) / mo")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.accentColor)
                        }

                        if let surplus = position.monthlySurplus {
                            HStack {
                                Text("Available Monthly Surplus")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(surplus.toCurrency())
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.green)
                            }

                            if combined > surplus {
                                Label("Combined goal savings exceed recorded monthly surplus. Consider lengthening timelines or stepping up SIPs.", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                    .padding(8)
                                    .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                            } else {
                                Label("Comfortably funded within your monthly surplus capacity!", systemImage: "checkmark.seal.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.green)
                                    .padding(8)
                                    .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }
            }

            // Interactive What-If Monthly Contribution
            journeySection("What-If? Investment Simulator", icon: "slider.horizontal.2.square", tint: .purple) {
                Text("Simulate how altering your monthly investment impacts long-term goals.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("Current Recorded SIP:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(position.monthlyInvestmentContribution?.toCurrency() ?? "₹41,653")
                        .font(.subheadline.weight(.bold))
                }

                // Quick Bump Buttons
                HStack(spacing: 8) {
                    bumpContributionChip("+₹5,000", 5_000)
                    bumpContributionChip("+₹10,000", 10_000)
                    bumpContributionChip("+₹20,000", 20_000)
                }

                HStack(spacing: 8) {
                    TextField("Enter monthly scenario amount · e.g. 50000", text: $contributionText)
                        .keyboardType(.decimalPad)
                        .font(.subheadline)
                        .padding(12)
                        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                        .onChange(of: contributionText) { _, val in
                            var updated = journey
                            updated.monthlyInvestmentWhatIf = parseFinancialAmount(val)
                            appState.updateFinancialPlanningJourney(updated)
                        }
                }
            }

            // Projection Horizon
            if let year = throughYear, let rows = FinancialPlanningEngine.projection(profile: profile, journey: journey, throughYear: year) {
                journeySection("Hypothetical Projection to \(year)", icon: "chart.line.uptrend.xyaxis", tint: .green) {
                    ForEach(rows.prefix(4)) { row in
                        HStack {
                            Text("Year \(row.year)")
                                .font(.subheadline.weight(.bold))
                            Spacer()
                            Text("Est. Balance: \(row.investmentBalance?.toCurrency() ?? "—")")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else if let latestYear = latestPlanningYear {
                journeySection("Simulation Horizon", icon: "hourglass", tint: .indigo) {
                    Text("Select a future year to preview capital projections:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("Simulate through", selection: $throughYear) {
                        Text("Choose a Horizon Year").tag(Int?.none)
                        ForEach(Calendar.current.component(.year, from: Date()) + 1...latestYear, id: \.self) { yr in
                            Text("Through \(yr)").tag(Optional(yr))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.blue)
                }
            }
        }
    }

    private func bumpContributionChip(_ label: String, _ addAmount: Double) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            let base = position.monthlyInvestmentContribution ?? 41_653
            let newAmount = base + addAmount
            contributionText = String(format: "%.0f", newAmount)
            var updated = journey
            updated.monthlyInvestmentWhatIf = newAmount
            appState.updateFinancialPlanningJourney(updated)
        } label: {
            Text(label)
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.purple.opacity(0.1), in: Capsule())
                .foregroundStyle(.purple)
        }
    }

    // MARK: - STEP 6: Strategy / Build your financial strategy
    private var strategyContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Blueprint Card
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LinearGradient(colors: [Color.blue.opacity(0.12), Color.indigo.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "chart.pie.fill")
                            .foregroundStyle(Color.accentColor)
                        Text("Executive Financial Blueprint")
                            .font(.headline.weight(.bold))
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Monthly Capacity")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(position.monthlySurplus?.toCurrency() ?? "₹43,000")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Color.accentColor)
                        }

                        Divider().frame(height: 36)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Active Goals")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("\(orderedGoalDrafts.count + goals.count)")
                                .font(.title3.weight(.bold))
                        }

                        Divider().frame(height: 36)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Life Events")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("\(journey.events.count)")
                                .font(.title3.weight(.bold))
                        }
                    }
                }
                .padding(16)
            }

            // Asset Allocation Strategy Buckets
            journeySection("Recommended Investment Buckets", icon: "square.grid.3x3.fill", tint: .indigo) {
                strategyBucketCard("Short-Term Horizon (< 3 Yrs)", "Liquid Funds, Arbitrage, High-Yield FDs", "Capital Safety & Liquidity", .blue)
                strategyBucketCard("Medium-Term Horizon (3-7 Yrs)", "Balanced Advantage, Multi-Asset, Large Cap", "Stable Growth with Cushion", .purple)
                strategyBucketCard("Long-Term Horizon (7+ Yrs)", "Flexi-cap, Mid-cap, Small-cap Equities", "Max Wealth Compounding", .green)
            }

            // Strategy Links
            journeySection("Deep-Dive Strategy Tools", icon: "sparkles", tint: .blue) {
                strategyActionLink("Start Planning a Specific Goal", "Run calculator & model SIP", "chart.pie.fill", .blue) {
                    GoalSelectionView(reviewJourneyFirst: false)
                }
                strategyActionLink("Review Financial Health Readiness", "Audit reserves & insurance safety net", "heart.text.square.fill", .green) {
                    FinancialDecisionCenterView()
                }
                strategyActionLink("Explore Stock & Fund Intelligence", "AI insights & mutual fund facts", "chart.line.uptrend.xyaxis", .purple) {
                    InvestmentIntelligenceView()
                }
                strategyActionLink("Review Health Action Roadmap", "Personalized improvement checklist", "checklist", .orange) {
                    PersonalizedHealthPlanView()
                }
            }
        }
    }

    private func strategyBucketCard(_ title: String, _ instruments: String, _ purpose: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
                Spacer()
                Text(purpose)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(instruments)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private func strategyActionLink<Destination: View>(_ title: String, _ subtitle: String, _ icon: String, _ tint: Color, destination: () -> Destination) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(tint.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .foregroundStyle(tint)
                        .font(.system(size: 16, weight: .bold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - STEP 7: Actions / Master Multi-Goal Timeline Plan
    private var actionsContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Master Plan Executive Banner
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                        Text("Master Timeline Execution Plan")
                            .font(.headline.weight(.bold))
                        Spacer()
                        Text("\(calculatedGoalPlans.count) Goals Active")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.12), in: Capsule())
                    }

                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Total Monthly SIP Needed")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(totalMonthlySIPNeeded.toCurrency() + " / mo")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Color.accentColor)
                        }

                        Divider().frame(height: 36)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Available Monthly Surplus")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(availableMonthlyCapacity.toCurrency())
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Color.green)
                        }
                    }

                    // Surplus coverage status bar
                    let surplus = availableMonthlyCapacity
                    let coverageRatio = totalMonthlySIPNeeded > 0 ? min(1.5, surplus / totalMonthlySIPNeeded) : 1.0

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(coverageRatio >= 1.0 ? "Surplus Coverage: 100% Fully Funded" : "Surplus Coverage: \(Int(coverageRatio * 100))% Funded")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(coverageRatio >= 1.0 ? Color.green : Color.orange)
                            Spacer()
                            Text(coverageRatio >= 1.0 ? "Comfortable Margin" : "10% Step-Up Recommended")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(value: min(1.0, coverageRatio), total: 1.0)
                            .tint(coverageRatio >= 1.0 ? .green : .orange)
                            .scaleEffect(y: 0.8)
                    }

                    // Strategic Waterfall Breakdown of ₹43k Surplus
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.branch")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.accentColor)
                            Text("Strategic Surplus Allocation (Priority Order)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.primary)
                        }

                        if let topGoal = calculatedGoalPlans.first {
                            let allocated = min(surplus, topGoal.monthlySIP)
                            let gap = max(0, topGoal.monthlySIP - allocated)

                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text("Top Focus: Fulfill **\(topGoal.name)** First")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(Color.accentColor)
                                    Spacer()
                                    Text("Timeline: \(topGoal.yearsFromNow) yrs")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }

                                HStack {
                                    Text("Dedicated from Surplus:")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(allocated.toCurrency()) / mo (100% Focused)")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(Color.green)
                                }

                                if gap > 0 {
                                    HStack {
                                        Text("Balance required for target:")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        return                                 Spacer()
                                        Text("+\(gap.toCurrency()) / mo via bonuses & 11% salary raise")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                            .padding(10)
                            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

                            if calculatedGoalPlans.count > 1 {
                                let otherGoals = calculatedGoalPlans.dropFirst()
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "arrow.turn.down.right")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text("Next Milestones (\(otherGoals.count)): \(otherGoals.map(\.name).joined(separator: ", ")) inherit the full surplus once \(topGoal.name) finishes (or in Month 15 under accelerated simulation).")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 2)
                            }
                        }
                    }

                    HStack {
                        Text("Total Projected Wealth Across Horizons:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(totalWealthProjected.toCurrency())
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.purple)
                    }
                }
                .padding(16)
            }

            // Strategy Mode Selector & All Goals
            VStack(alignment: .leading, spacing: 14) {
                // Strategy Mode Selector (Sequential Focus vs Activate All)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Execution Strategy:")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                    HStack(spacing: 8) {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                executionMode = .sequential
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "1.circle.fill")
                                Text("Priority First")
                            }
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(executionMode == .sequential ? Color.accentColor : Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(executionMode == .sequential ? .white : .primary)
                        }

                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                executionMode = .activateAll
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.horizontal.fill")
                                Text("Activate All")
                            }
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(executionMode == .activateAll ? Color.accentColor : Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(executionMode == .activateAll ? .white : .primary)
                        }
                    }

                    // Explanatory Banner
                    if executionMode == .sequential {
                        if let firstGoal = calculatedGoalPlans.first {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                                    .font(.caption)
                                Text("Focusing 100% of capacity (**\(min(availableMonthlyCapacity, firstGoal.monthlySIP).toCurrency())/mo**) on **\(firstGoal.name)** first. When it completes, start the next priority goal from that date with rolled-over capacity.")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineSpacing(2)
                            }
                            .padding(10)
                            .background(Color.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                        }
                    } else {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text("All \(calculatedGoalPlans.count) goals active simultaneously! Monthly capacity of \(availableMonthlyCapacity.toCurrency()) is distributed across every goal concurrently.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineSpacing(2)
                        }
                        .padding(10)
                        .background(Color.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(14)
                .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))

                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(Color.accentColor)
                    Text("All Goals Across Your Timeline")
                        .font(.headline.weight(.bold))
                    Spacer()
                }

                if calculatedGoalPlans.isEmpty {
                    ContentUnavailableView(
                        "No goals ready",
                        systemImage: "target",
                        description: Text("Add goals in Step 2 to generate your timeline execution plan.")
                    )
                } else {
                    ForEach(calculatedGoalPlans) { plan in
                        completeGoalPlanCard(plan)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func completeGoalPlanCard(_ plan: CalculatedGoalPlan) -> some View {
        let chosenIdx = chosenPlanIndex[plan.id]
        let chosenPlanNames = ["Plan 1: SIP", "Plan 2: Loan", "Plan 3: Stress-Test"]
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            selectedGoalPlanOption = 0
            simulatingGoal = plan
        } label: {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(goalTint(for: plan.category).opacity(0.14))
                        .frame(width: 44, height: 44)
                    Image(systemName: goalIcon(for: plan.category))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(goalTint(for: plan.category))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.primary)

                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text("\(plan.yearsFromNow) yrs from now • \(plan.targetDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Color.accentColor)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(priorityLabel(plan.priority))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(priorityColor(plan.priority))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(priorityColor(plan.priority).opacity(0.12), in: Capsule())

                    if let idx = chosenIdx {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 9))
                            Text(chosenPlanNames[idx])
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.green, in: Capsule())
                    } else {
                        HStack(spacing: 3) {
                            Image(systemName: "play.circle")
                                .font(.system(size: 9))
                            Text("Tap to Simulate")
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundStyle(.purple)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.purple.opacity(0.10), in: Capsule())
                    }
                }
            }

            Divider()

            // Financial Breakdown: Base Cost -> Inflation Target & Required Monthly SIP
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Target Corpus")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(plan.inflationAdjustedAmount.toCurrency())
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                    Text("Base: \(plan.baseAmount.toCurrency())")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider().frame(height: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Recommended Monthly SIP")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                    Text(plan.monthlySIP.toCurrency() + " / mo")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                    Text("Horizon: \(plan.yearsFromNow * 12) months")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(10)
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

            // Surplus Allocation Status according to executionMode & chosen plan
            let eff = effectiveAllocations[plan.id]
            let alloc = multiGoalOptimization.allocations.first(where: { $0.id == plan.id })

            if executionMode == .sequential {
                if let eff = eff, eff.isLoan {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Image(systemName: "banknote.fill")
                                .foregroundStyle(Color.purple)
                                .font(.caption)
                            Text(eff.statusTitle)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.primary)
                            Spacer()
                        }
                        Text(eff.statusDescription)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.teal)
                            .padding(.leading, 18)
                    }
                    .padding(8)
                    .background(Color.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                } else if let eff = eff, eff.isDualTrackUnlocked {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(Color.teal)
                                .font(.caption)
                            Text(eff.statusTitle)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.primary)
                            Spacer()
                        }
                        Text(eff.statusDescription)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.secondary)
                            .padding(.leading, 18)
                    }
                    .padding(8)
                    .background(Color.teal.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                } else {
                    let isFirstGoal = calculatedGoalPlans.first?.id == plan.id
                    HStack(spacing: 6) {
                        Image(systemName: isFirstGoal ? "checkmark.seal.fill" : "clock.arrow.circlepath")
                            .foregroundStyle(isFirstGoal ? Color.green : Color.orange)
                            .font(.caption)
                        if isFirstGoal {
                            Text(eff?.statusTitle ?? "Priority First Focus: \(min(availableMonthlyCapacity, plan.monthlySIP).toCurrency())/mo allocated (100% focused)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.green)
                        } else {
                            let priorGoal = calculatedGoalPlans.first
                            Text("Sequential Queue: Starts after \(alloc?.queueStartsAfterGoalName ?? (priorGoal?.name ?? "Goal 1")) completes in \(priorGoal?.targetDate.formatted(date: .abbreviated, time: .omitted) ?? "Year 2")")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(8)
                    .background(isFirstGoal ? Color.green.opacity(0.08) : Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                }
            } else {
                let allocated = eff?.allocatedMonthlyCapacity ?? (alloc?.allocatedMonthlyCapacity ?? (totalMonthlySIPNeeded > 0 ? (plan.monthlySIP / totalMonthlySIPNeeded) * availableMonthlyCapacity : 0))
                let deficit = max(0, (eff?.monthlyCommitment ?? plan.monthlySIP) - allocated)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("Every Month Allocation: \(allocated.toCurrency()) / mo (Active Concurrently)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    if deficit > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.forward.circle")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 10))
                            Text("Monthly Gap: \(deficit.toCurrency()) / mo (Bridgeable via bonus or 10% annual salary step-up)")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.leading, 18)
                    }
                }
                .padding(8)
                .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }

            // Recommended Allocation & Fund Types
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Suggested Asset Allocation:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(plan.assetAllocation)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(goalTint(for: plan.category))
                }

                HStack {
                    Text("Fund Categories:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(plan.recommendedFunds)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }

            // Customize Questionnaire Drill-Down — uses simultaneousGesture so it
            // fires its own action without cancelling the outer card tap.
            HStack {
                Image(systemName: "slider.horizontal.3")
                Text("Customize / Fine-Tune Plan Parameters")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(goalTint(for: plan.category))
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                customizingGoalCategory = plan
            })
        }
        .padding(14)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    chosenPlanIndex[plan.id] != nil ? Color.green.opacity(0.4) : Color.primary.opacity(0.06),
                    lineWidth: chosenPlanIndex[plan.id] != nil ? 2 : 1
                )
        }
        }
        .buttonStyle(.plain)
    }


    private func saveAndActivateCompletePlan() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        for draft in journey.goalDrafts {
            let exists = goals.contains { $0.id == draft.id || $0.goalName.localizedCaseInsensitiveCompare(draft.name) == .orderedSame }
            if !exists {
                let newGoal = AstraGoal(
                    id: draft.id,
                    goalName: draft.name,
                    targetAmount: draft.targetAmount ?? 1_000_000,
                    currentAmount: 0,
                    targetDate: draft.targetDate ?? Calendar.current.date(byAdding: .year, value: 3, to: Date())!
                )
                appState.addGoal(newGoal)
            }
        }
        var updated = journey
        updated.currentPhase = .actions
        appState.updateFinancialPlanningJourney(updated)

        // Construct and persist full MasterFinancialPlan snapshot
        let modeString = executionMode == .sequential ? "Sequential Focus" : "Activate All"
        let activeGoals: [ActiveGoalPlan] = calculatedGoalPlans.map { plan in
            let eff = effectiveAllocations[plan.id]
            let alloc = multiGoalOptimization.allocations.first(where: { $0.id == plan.id })
            let allocated = eff?.allocatedMonthlyCapacity ?? (alloc?.allocatedMonthlyCapacity ?? 0)
            let chosenIdx = chosenPlanIndex[plan.id]
            let stratName: String = {
                if let idx = chosenIdx {
                    if idx == 1 { return "Plan 2: Traditional Loan" }
                    if idx == 2 { return "Plan 3: Loan Stress-Test" }
                    return "Plan 1: Pure SIP"
                }
                return plan.assetAllocation
            }()
            let note = eff?.statusTitle ?? (alloc?.queueStartsAfterGoalName != nil ? "Queued after \(alloc!.queueStartsAfterGoalName!)" : "Active")
            return ActiveGoalPlan(
                id: plan.id,
                name: plan.name,
                category: plan.category,
                targetBaseAmount: plan.baseAmount,
                inflationCorpus: plan.inflationAdjustedAmount,
                currentSaved: 0,
                monthlySIPRequired: eff?.monthlyCommitment ?? plan.monthlySIP,
                allocatedMonthlySurplus: allocated,
                targetDate: plan.targetDate,
                strategyName: stratName,
                status: .onTrack,
                notes: note
            )
        }
        let timelineItems: [MasterTimelineItem] = calculatedGoalPlans.map { plan in
            let yr = Calendar.current.component(.year, from: plan.targetDate)
            return MasterTimelineItem(
                id: plan.id,
                year: yr,
                title: plan.name,
                category: plan.category,
                targetCorpus: plan.inflationAdjustedAmount,
                date: plan.targetDate,
                isCompleted: false
            )
        }
        let masterPlan = MasterFinancialPlan(
            version: 1,
            createdAt: Date(),
            lastRecalculatedAt: Date(),
            planningMode: modeString,
            totalMonthlyPlanningCapacity: availableMonthlyCapacity,
            totalMonthlySIPNeeded: totalMonthlySIPNeeded,
            totalProjectedWealth: totalWealthProjected,
            activeGoals: activeGoals,
            timeline: timelineItems,
            trackingStatus: availableMonthlyCapacity >= totalMonthlySIPNeeded ? .fullyResilient : .onTrackWithStepUp,
            summaryNotes: "Configured via New Investment Plan Journey with \(modeString) strategy."
        )
        appState.updateMasterFinancialPlan(masterPlan)

        showPlanSavedConfirmation = true
    }

    private var masterPlanCelebrationSheet: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.green)
            }
            .padding(.top, 24)

            VStack(spacing: 8) {
                Text("Master Plan Activated!")
                    .font(.title2.weight(.bold))
                Text("All \(calculatedGoalPlans.count) goals across your timeline have been saved and configured in your Planner.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            VStack(spacing: 8) {
                HStack {
                    Text("Total Monthly Investment:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(totalMonthlySIPNeeded.toCurrency() + " / mo")
                        .font(.headline.weight(.bold))
                }
                HStack {
                    Text("Total Wealth Target:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(totalWealthProjected.toCurrency())
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)

            Button {
                showPlanSavedConfirmation = false
                if let onComplete {
                    onComplete()
                } else {
                    dismiss()
                }
            } label: {
                Text("Go to Planner")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AppTheme.accentGradient, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private var activeCustomizingPlan: CalculatedGoalPlan? {
        guard let id = customizingGoalID else { return nil }
        return calculatedGoalPlans.first(where: { $0.id == id })
    }

    // MARK: - Dedicated Goal Questionnaire Sheet (Wedding Questionnaire, etc.)
    private func goalQuestionnaireSheet(plan: CalculatedGoalPlan) -> some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if plan.category.localizedCaseInsensitiveContains("Marriage") || plan.category.localizedCaseInsensitiveContains("Wedding") || plan.name.localizedCaseInsensitiveContains("Marriage") {
                        WeddingQuestionnaire(goalAccentColor: .pink)
                    } else if plan.category.localizedCaseInsensitiveContains("Home") {
                        HomeQuestionnaire(goalAccentColor: .green)
                    } else if plan.category.localizedCaseInsensitiveContains("Vehicle") || plan.category.localizedCaseInsensitiveContains("Car") {
                        VehicleQuestionnaire(goalAccentColor: .orange)
                    } else if plan.category.localizedCaseInsensitiveContains("Travel") || plan.category.localizedCaseInsensitiveContains("Trip") {
                        TravelQuestionnaire(goalAccentColor: .cyan)
                    } else if plan.category.localizedCaseInsensitiveContains("Wealth") {
                        WealthQuestionnaire(goalAccentColor: .indigo)
                    } else if plan.category.localizedCaseInsensitiveContains("Education") || plan.category.localizedCaseInsensitiveContains("Child") {
                        EducationQuestionnaire(profileAge: profile?.basicDetails.age, goalAccentColor: .blue)
                    } else {
                        OtherQuestionnaire(goalAccentColor: .blue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .navigationTitle("\(plan.name) Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        customizingGoalCategory = nil
                    }
                    .font(.headline.weight(.semibold))
                }
            }
        }
    }

    // MARK: - Goal-Specific 3-Plan Simulation Sheet
    private func goalSpecificSimulationSheet(plan: CalculatedGoalPlan) -> some View {
        // Build InvestmentPlanInputModel from the CalculatedGoalPlan so we can
        // drive the real Plan1/2/3 detail views with accurate numbers.
        let input = makeInputModel(for: plan)
        let fullPlan = InvestmentPlannerEngine.generateFullPlan(input: input, profile: profile)
        let isLoanEligible = fullPlan.goalCategory != .retirement && fullPlan.goalCategory != .wealthCreation
        let chosenIdx = chosenPlanIndex[plan.id]

        // Next priority goal (after this one) for cascade info
        let nextGoal = calculatedGoalPlans.first(where: { $0.id != plan.id && $0.priority > plan.priority })
            ?? calculatedGoalPlans.first(where: { $0.id != plan.id })

        return NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // ── Header ──────────────────────────────────────────────
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(goalTint(for: plan.category).opacity(0.14))
                                .frame(width: 52, height: 52)
                            Image(systemName: goalIcon(for: plan.category))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(goalTint(for: plan.category))
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(plan.name) — 3 Plans")
                                .font(.title3.weight(.bold))
                            Text("Inflation-adjusted target: \(plan.inflationAdjustedAmount.toCurrency()) in \(plan.yearsFromNow) yrs")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let idx = chosenIdx {
                            VStack(spacing: 2) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.title3)
                                    .foregroundStyle(.green)
                                Text(["Plan 1", "Plan 2", "Plan 3"][idx])
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

                    // ── Intro explanation ────────────────────────────────────
                    Text("Review each strategy below. Tap a card to explore the full detail simulation. When ready, choose the plan you want to follow.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 2)

                    // ══════════════════════════════════════════════════════════
                    // PLAN 1: SIP / Pure Savings
                    // ══════════════════════════════════════════════════════════
                    planSelectionCard(
                        planNumber: 1,
                        title: "SIP + Diversification",
                        subtitle: "Systematic monthly savings across equity, debt & gold. Zero debt, full corpus built by discipline.",
                        icon: "chart.line.uptrend.xyaxis.circle.fill",
                        color: .blue,
                        tag: "Steady Wealth Builder",
                        metric: "₹\(Int(plan.monthlySIP).formatted()) / mo",
                        isChosen: chosenIdx == 0,
                        loanEMI: nil,
                        nextGoalName: nextGoal?.name,
                        residualSurplus: nil
                    ) {
                        // Choose Plan 1
                        withAnimation(.spring(response: 0.35)) {
                            chosenPlanIndex[plan.id] = 0
                        }
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        simulatingGoal = nil
                    } detailDestination: {
                        AnyView(
                            Plan1DetailView(input: input, result: fullPlan.plan1)
                                .environment(appState)
                        )
                    }

                    // ══════════════════════════════════════════════════════════
                    // PLAN 2: Loan / Debt Scenario (only for loan-eligible goals)
                    // ══════════════════════════════════════════════════════════
                    if isLoanEligible, let plan2Result = fullPlan.plan2 {
                        let loanEMI = plan2Result.monthlyEMI
                        let residual = max(0, availableMonthlyCapacity - loanEMI)

                        planSelectionCard(
                            planNumber: 2,
                            title: "Traditional Loan / Debt",
                            subtitle: "Bank loan for immediate acquisition. EMI is fixed; surplus flows to the next priority goal.",
                            icon: "banknote.fill",
                            color: .purple,
                            tag: "Immediate Access",
                            metric: "EMI ₹\(Int(loanEMI).formatted()) / mo",
                            isChosen: chosenIdx == 1,
                            loanEMI: loanEMI,
                            nextGoalName: nextGoal?.name,
                            residualSurplus: residual > 0 ? residual : nil
                        ) {
                            withAnimation(.spring(response: 0.35)) {
                                chosenPlanIndex[plan.id] = 1
                            }
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            simulatingGoal = nil
                        } detailDestination: {
                            AnyView(
                                Plan2DetailView(input: input, result: plan2Result)
                                    .environment(appState)
                            )
                        }
                    }

                    // ══════════════════════════════════════════════════════════
                    // PLAN 3: Loan Stress-Test
                    // ══════════════════════════════════════════════════════════
                    if let plan3Result = fullPlan.plan3 {
                        let stressEMI = plan3Result.monthlyEMI
                        let residual = max(0, availableMonthlyCapacity - stressEMI)

                        planSelectionCard(
                            planNumber: 3,
                            title: "Loan Stress-Test Scenario",
                            subtitle: "Debt-funded investing simulation. High-risk: shows how leverage amplifies gains & losses.",
                            icon: "arrow.up.right.circle.fill",
                            color: .orange,
                            tag: "High-Risk Simulation",
                            metric: "Loan: \(plan3Result.loanAmount.toCurrency())",
                            isChosen: chosenIdx == 2,
                            loanEMI: stressEMI,
                            nextGoalName: nextGoal?.name,
                            residualSurplus: residual > 0 ? residual : nil
                        ) {
                            withAnimation(.spring(response: 0.35)) {
                                chosenPlanIndex[plan.id] = 2
                            }
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            simulatingGoal = nil
                        } detailDestination: {
                            AnyView(
                                Plan3DetailView(input: input, result: plan3Result)
                                    .environment(appState)
                            )
                        }
                    }

                    Spacer().frame(height: 20)
                }
                .padding(20)
            }
            .navigationTitle("Simulate: \(plan.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { simulatingGoal = nil }
                        .font(.headline.weight(.semibold))
                }
            }
        }
    }

    // MARK: - Reusable Plan Selection Card
    @ViewBuilder
    private func planSelectionCard(
        planNumber: Int,
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        tag: String,
        metric: String,
        isChosen: Bool,
        loanEMI: Double?,
        nextGoalName: String?,
        residualSurplus: Double?,
        onChoose: @escaping () -> Void,
        @ViewBuilder detailDestination: () -> AnyView
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Plan number badge
            HStack {
                Text("PLAN \(planNumber)")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(isChosen ? Color.green : color, in: Capsule())
                if isChosen {
                    Label("Active Plan", systemImage: "checkmark.seal.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.green)
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Main card content — NavigationLink to detail view
            NavigationLink(destination: detailDestination()) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center, spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(color.opacity(0.12))
                                .frame(width: 50, height: 50)
                            Image(systemName: icon)
                                .font(.system(size: 22))
                                .foregroundStyle(color)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                            Text(subtitle)
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.right.circle")
                                .font(.title3)
                                .foregroundStyle(color.opacity(0.7))
                            Text("Explore")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(color.opacity(0.7))
                        }
                    }

                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(color)
                            Text(tag)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(color.opacity(0.08))
                        .clipShape(Capsule())

                        Spacer()

                        Text(metric)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
            .buttonStyle(.plain)

            // Loan EMI cascade banner (shown only for loan plans)
            if let emi = loanEMI, let surplus = residualSurplus, surplus > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundStyle(.teal)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("EMI ₹\(Int(emi).formatted())/mo deducted • Surplus ₹\(Int(surplus).formatted())/mo auto-flows to \(nextGoalName ?? "next goal")")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.teal)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.teal.opacity(0.07))
            }

            Divider().padding(.horizontal, 14)

            // Choose This Plan CTA
            Button {
                onChoose()
            } label: {
                HStack {
                    Image(systemName: isChosen ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18, weight: .bold))
                    Text(isChosen ? "✓ Active Plan Chosen" : "Choose This Plan")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Spacer()
                }
                .foregroundStyle(isChosen ? .green : color)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(isChosen ? Color.green.opacity(0.06) : color.opacity(0.05))
            }
            .buttonStyle(.plain)
        }
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isChosen ? Color.green.opacity(0.6) : color.opacity(0.15), lineWidth: isChosen ? 2 : 1)
        }
        .shadow(color: isChosen ? .green.opacity(0.15) : .black.opacity(0.04), radius: isChosen ? 12 : 6, x: 0, y: 4)
    }


    private func goalPlanSequentialCard(plan: CalculatedGoalPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Plan 1: Standard Sequential", systemImage: "arrow.right.circle.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.blue)
                Spacer()
                Text("1 Goal at a Time")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.12), in: Capsule())
            }

            Text("Full monthly savings are dedicated to \(plan.name) over its planned horizon of \(plan.yearsFromNow).0 years (\(plan.yearsFromNow * 12) months). Subsequent goals wait in queue.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                timelineStepRow(month: "Month 1–\(plan.yearsFromNow * 12)", title: "Focus on \(plan.name)", desc: "100% surplus allocated. Completes in Month \(plan.yearsFromNow * 12).", color: .blue)
                timelineStepRow(month: "Month \(plan.yearsFromNow * 12 + 1)+", title: "Next Priority Goal Begins", desc: "Pipeline goals start only after \(plan.name) is fully achieved.", color: .secondary)
            }

            HStack {
                Text("Simultaneous Goals Running:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("1 Goal (Single-Thread)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
            }
            .padding(10)
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18).stroke(Color.blue.opacity(0.2), lineWidth: 1)
        }
    }

    private func goalPlanAcceleratedCard(plan: CalculatedGoalPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Plan 2: Accelerated Early Completion", systemImage: "bolt.badge.clock.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.purple)
                Spacer()
                Text("2 Goals Simultaneously 🔥")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.12), in: Capsule())
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Time period was \(plan.yearsFromNow).0 years, but goal achieved in 1.2 years (14.4 months)!")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.accentColor)

                Text("With 14% portfolio alpha and step-up savings, \(plan.name) reaches 100% target corpus early, unlocking your surplus ahead of schedule.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(Color.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                timelineStepRow(month: "Month 1–14", title: "\(plan.name) Completed (1.2 Yrs)!", desc: "100% target corpus achieved 9.6 months earlier than planned.", color: .green)
                timelineStepRow(month: "Month 15–\(max(24, plan.yearsFromNow * 12))", title: "Run 2 Goals Simultaneously in Parallel!", desc: "From Month 15 onwards, your surplus is liberated early! You now run \(plan.name) completion buffer AND the next priority goal concurrently in parallel!", color: .purple)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Time Saved")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("9.6 Months Early")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Parallel Execution")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("2 Goals Running Concurrently")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.purple)
                }
            }
            .padding(10)
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18).stroke(Color.purple.opacity(0.3), lineWidth: 1.5)
        }
    }

    private func goalPlanDualTrackCard(plan: CalculatedGoalPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Plan 3: Pro-Rata Dual-Track", systemImage: "arrow.triangle.merge")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.orange)
                Spacer()
                Text("Parallel from Day 1")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.12), in: Capsule())
            }

            Text("Split the monthly surplus from Day 1 between \(plan.name) and the next priority milestone so both advance simultaneously.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                timelineStepRow(month: "Day 1 Split", title: "65% Surplus to \(plan.name)", desc: "\(plan.name) completes in ~\(String(format: "%.1f", Double(plan.yearsFromNow) * 1.15)) years.", color: .orange)
                timelineStepRow(month: "Day 1 Split", title: "35% Surplus to Next Goal", desc: "Next goal is simultaneously 45% funded on the same date!", color: .teal)
            }

            HStack {
                Text("Simultaneous Goals Running:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("2 Goals from Day 1")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.orange)
            }
            .padding(10)
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18).stroke(Color.orange.opacity(0.2), lineWidth: 1)
        }
    }

    private func goalSimulationComparisonMatrix(plan: CalculatedGoalPlan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Scenario Comparison Summary")
                .font(.subheadline.weight(.bold))

            HStack(spacing: 8) {
                comparisonColumn(title: "Sequential", months: "\(plan.yearsFromNow * 12) Mo", parallel: "1 Goal", highlight: false)
                comparisonColumn(title: "Accelerated", months: "14.4 Mo", parallel: "2 Goals 🔥", highlight: true)
                comparisonColumn(title: "Dual-Track", months: "\(Int(Double(plan.yearsFromNow * 12) * 1.15)) Mo", parallel: "2 Goals", highlight: false)
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Inline Goal Customize Sheet
    private func inlineGoalCustomizeSheet(plan: CalculatedGoalPlan) -> some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(goalTint(for: plan.category).opacity(0.14))
                                .frame(width: 48, height: 48)
                            Image(systemName: goalIcon(for: plan.category))
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(goalTint(for: plan.category))
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(plan.name)
                                .font(.title3.weight(.bold))
                            Text("Updates recalculate the Master Plan immediately")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Target Budget / Base Cost
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Estimated Budget (₹)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)

                        TextField("Amount (e.g. 2500000)", text: $customizeAmountText)
                            .keyboardType(.decimalPad)
                            .font(.title3.weight(.bold).monospacedDigit())
                            .padding(14)
                            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach([1_000_000.0, 1_500_000.0, 2_000_000.0, 2_500_000.0, 3_500_000.0, 5_000_000.0, 10_000_000.0], id: \.self) { amt in
                                    Button {
                                        customizeAmountText = String(format: "%.0f", amt)
                                    } label: {
                                        Text(amt.toCurrency())
                                            .font(.caption2.weight(.semibold))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(
                                                (parseFinancialAmount(customizeAmountText) == amt) ? Color.accentColor : Color.primary.opacity(0.06),
                                                in: Capsule()
                                            )
                                            .foregroundStyle((parseFinancialAmount(customizeAmountText) == amt) ? .white : .primary)
                                    }
                                }
                            }
                        }
                    }

                    // Timeline (Years from now)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Target Timeline")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(customizeYears) \(customizeYears == 1 ? "Year" : "Years") from now")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.accentColor)
                        }

                        Stepper(value: $customizeYears, in: 1...30) {
                            Text("Horizon: \(customizeYears * 12) Months")
                                .font(.subheadline)
                        }
                        .padding(14)
                        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                    }

                    // Live calculation preview
                    if let parsedAmt = parseFinancialAmount(customizeAmountText) {
                        let inflation = journey.assumptions.inflationRate ?? 0.06
                        let futureTarget = parsedAmt * pow(1 + inflation, Double(customizeYears))
                        let months = Double(customizeYears * 12)
                        let returnRate: Double = customizeYears < 3 ? 0.07 : (customizeYears < 7 ? 0.10 : (journey.assumptions.investmentReturnRate ?? 0.11))
                        let monthlyRate = returnRate / 12.0
                        let newSIP = monthlyRate > 0 ? (futureTarget * monthlyRate) / (pow(1 + monthlyRate, months) - 1) : futureTarget / months

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Live Recalculation Preview:")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)
                            HStack {
                                Text("New Target Corpus (at \(Int(inflation * 100))% infl.):")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(futureTarget.toCurrency())
                                    .font(.caption2.weight(.bold))
                            }
                            HStack {
                                Text("New Recommended Monthly SIP:")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(newSIP.toCurrency() + " / mo")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding(12)
                        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if let newAmount = parseFinancialAmount(customizeAmountText) {
                            updateGoalDraft(plan.id) { draft in
                                draft.targetAmount = newAmount
                                draft.targetDate = Calendar.current.date(byAdding: .year, value: customizeYears, to: Date())
                            }
                        }
                        customizingGoalID = nil
                    } label: {
                        Text("Apply & Update Master Plan")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AppTheme.accentGradient, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.top, 4)
                }
                .padding(20)
            }
            .navigationTitle("Customize Plan Parameters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        customizingGoalID = nil
                    }
                }
            }
        }
    }

    // MARK: - Goal Simulation Sheet (3 Plans & Early Finish Scenario)
    private var goalSimulationSheet: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Dynamic Goal Simulation")
                            .font(.title2.weight(.bold))
                        Text("Simulation based on recorded ₹43,000 monthly surplus and timeline data.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Scenario Picker
                    Picker("Simulation Scenario", selection: $selectedSimulationPlan) {
                        Text("Sequential").tag(0)
                        Text("Accelerated (1.2Y) 🚀").tag(1)
                        Text("Dual-Track").tag(2)
                    }
                    .pickerStyle(.segmented)

                    if selectedSimulationPlan == 0 {
                        simulationSequentialCard
                    } else if selectedSimulationPlan == 1 {
                        simulationAcceleratedCard
                    } else {
                        simulationDualTrackCard
                    }

                    // Comparison Matrix
                    simulationComparisonMatrix
                }
                .padding(20)
            }
            .navigationTitle("Goal Simulation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showSimulationSheet = false
                    }
                    .font(.headline.weight(.semibold))
                }
            }
        }
    }

    private var simulationSequentialCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Plan 1: Standard Sequential", systemImage: "arrow.right.circle.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.blue)
                Spacer()
                Text("1 Goal at a Time")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.12), in: Capsule())
            }

            Text("All available ₹43,000 monthly surplus is dedicated strictly to Goal 1 (e.g. \(calculatedGoalPlans.first?.name ?? "Marriage")) over its full 2.0-year horizon.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                timelineStepRow(month: "Month 1–24", title: "Focus on \(calculatedGoalPlans.first?.name ?? "Marriage")", desc: "100% surplus (₹43k/mo) deployed. Target reached in Month 24.", color: .blue)
                timelineStepRow(month: "Month 25+", title: "Pipeline Goals Begin", desc: "Next goal in line (\(calculatedGoalPlans.dropFirst().first?.name ?? "Children")) only starts after Year 2.", color: .secondary)
            }

            HStack {
                Text("Simultaneous Goals Running:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("1 Goal (Single-Thread)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
            }
            .padding(10)
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18).stroke(Color.blue.opacity(0.2), lineWidth: 1)
        }
    }

    private var simulationAcceleratedCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Plan 2: Accelerated Early Completion", systemImage: "bolt.badge.clock.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.purple)
                Spacer()
                Text("2 Goals Simultaneously 🔥")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.12), in: Capsule())
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Target was 2.0 Years, but Achieved in 1.2 Years (14.4 Months)!")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.accentColor)

                Text("With 14% portfolio return and 12% annual savings step-up, Goal 1 is 100% funded **9.6 months earlier** than planned.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(Color.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                timelineStepRow(month: "Month 1–14", title: "\(calculatedGoalPlans.first?.name ?? "Marriage") Completed (1.2 Yrs)!", desc: "Target corpus achieved 9.6 months early.", color: .green)
                timelineStepRow(month: "Month 15–36", title: "Run 2 Goals Simultaneously in Parallel!", desc: "Surplus of ₹43k/mo is liberated early! You now fund Goal 2 (\(calculatedGoalPlans.dropFirst().first?.name ?? "Children")) & Goal 3 concurrently without waiting!", color: .purple)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Time Saved")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("9.6 Months Early")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Parallel Goals Unlocked")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("2 Goals Concurrently")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.purple)
                }
            }
            .padding(10)
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18).stroke(Color.purple.opacity(0.3), lineWidth: 1.5)
        }
    }

    private var simulationDualTrackCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Plan 3: Pro-Rata Dual-Track", systemImage: "arrow.triangle.merge")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.orange)
                Spacer()
                Text("Parallel from Day 1")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.12), in: Capsule())
            }

            Text("Split the ₹43,000 monthly surplus right from Month 1 across your top two goals.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                timelineStepRow(month: "Day 1 Split", title: "₹28,000/mo to \(calculatedGoalPlans.first?.name ?? "Goal 1")", desc: "Goal 1 completes in ~2.3 years.", color: .orange)
                timelineStepRow(month: "Day 1 Split", title: "₹15,000/mo to \(calculatedGoalPlans.dropFirst().first?.name ?? "Goal 2")", desc: "Goal 2 is simultaneously 45% funded on the same date!", color: .teal)
            }

            HStack {
                Text("Simultaneous Goals Running:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("2 Goals from Month 1")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.orange)
            }
            .padding(10)
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18).stroke(Color.orange.opacity(0.2), lineWidth: 1)
        }
    }

    private var simulationComparisonMatrix: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Scenario Comparison Summary")
                .font(.subheadline.weight(.bold))

            HStack(spacing: 8) {
                comparisonColumn(title: "Sequential", months: "24 Mo", parallel: "1 Goal", highlight: false)
                comparisonColumn(title: "Accelerated", months: "14.4 Mo", parallel: "2 Goals 🔥", highlight: true)
                comparisonColumn(title: "Dual-Track", months: "28 Mo", parallel: "2 Goals", highlight: false)
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func comparisonColumn(title: String, months: String, parallel: String, highlight: Bool) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(highlight ? Color.purple : .secondary)
            Text(months)
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary)
            Text(parallel)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(highlight ? Color.purple : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(highlight ? Color.purple.opacity(0.1) : Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }

    private func timelineStepRow(month: String, title: String, desc: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(month)
                .font(.system(size: 10, weight: .bold).monospacedDigit())
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(color, in: RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func actionPhaseCard<Content: View>(_ badge: String, _ title: String, _ tint: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(badge)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tint, in: Capsule())
                Text(title)
                    .font(.subheadline.weight(.bold))
                Spacer()
            }
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        }
    }

    private func actionItemRow(_ text: String, _ icon: String, _ tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .font(.system(size: 15))
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
        }
    }

    // MARK: - Reordering Priority Content & Auto-Align
    private var prioritiesContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Tap arrows to set priority rank:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    autoAlignDatesByPriority()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "wand.and.stars")
                        Text("Auto-Align Dates")
                    }
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1), in: Capsule())
                }
            }

            ForEach(Array(priorityItems.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: 10) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(goalTint(for: item.category), in: Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.subheadline.weight(.bold))
                        Text(item.detail.isEmpty ? "Date & amount not set" : item.detail)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Button {
                            movePriority(item.id, by: -1)
                        } label: {
                            Image(systemName: "arrow.up")
                                .font(.caption.weight(.bold))
                                .frame(width: 28, height: 28)
                                .background(Color.primary.opacity(0.06), in: Circle())
                        }
                        .disabled(index == 0)

                        Button {
                            movePriority(item.id, by: 1)
                        } label: {
                            Image(systemName: "arrow.down")
                                .font(.caption.weight(.bold))
                                .frame(width: 28, height: 28)
                                .background(Color.primary.opacity(0.06), in: Circle())
                        }
                        .disabled(index == priorityItems.count - 1)
                    }
                }
                .padding(10)
                .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Smart Presets & Automation Logic
    private func smartPreset(for category: String, rank: Int) -> (amount: Double, years: Int) {
        let norm = category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if norm.contains("marriage") || norm.contains("wedding") {
            return (2_500_000, max(2, min(4, rank + 1)))
        } else if norm.contains("travel") || norm.contains("trip") {
            return (1_000_000, max(1, min(3, rank)))
        } else if norm.contains("vehicle") || norm.contains("car") || norm.contains("bike") {
            return (2_000_000, max(2, min(4, rank + 1)))
        } else if norm.contains("child") {
            return (4_000_000, max(3, min(6, rank + 2)))
        } else if norm.contains("education") || norm.contains("school") || norm.contains("college") {
            return (5_000_000, max(4, min(8, rank + 3)))
        } else if norm.contains("home") || norm.contains("house") {
            return (6_000_000, max(5, min(10, rank + 4)))
        } else if norm.contains("wealth") || norm.contains("build wealth") {
            return (10_000_000, max(7, min(15, rank + 5)))
        } else if norm.contains("retirement") {
            return (20_000_000, max(15, 25))
        } else if norm.contains("business") {
            return (2_500_000, max(3, min(6, rank + 2)))
        } else {
            return (1_500_000, max(2, min(5, rank + 1)))
        }
    }

    private func ensurePresetsForAllDrafts() {
        var updated = journey
        var changed = false
        for i in 0..<updated.goalDrafts.count {
            let preset = smartPreset(for: updated.goalDrafts[i].category, rank: i + 1)
            if updated.goalDrafts[i].targetAmount == nil || updated.goalDrafts[i].targetAmount == 0 {
                updated.goalDrafts[i].targetAmount = preset.amount
                changed = true
            }
            if updated.goalDrafts[i].targetDate == nil {
                updated.goalDrafts[i].targetDate = Calendar.current.date(byAdding: .year, value: preset.years, to: Date())
                changed = true
            }
        }
        if changed {
            appState.updateFinancialPlanningJourney(updated)
        }
    }

    private func autoAlignDatesByPriority() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        var updated = journey
        let order = priorityItems.map(\.id)
        for (index, id) in order.enumerated() {
            if let draftIndex = updated.goalDrafts.firstIndex(where: { $0.id == id }) {
                let category = updated.goalDrafts[draftIndex].category
                let preset = smartPreset(for: category, rank: index + 1)
                let years = max(index + 2, preset.years)
                updated.goalDrafts[draftIndex].targetDate = Calendar.current.date(byAdding: .year, value: years, to: Date())
            }
        }
        appState.updateFinancialPlanningJourney(updated)
    }

    private func toggleGoalDraft(category: String, name: String) {
        var updated = journey
        if let existing = updated.goalDrafts.first(where: { $0.category == category }) {
            updated.goalDrafts.removeAll { $0.id == existing.id }
        } else {
            let rank = updated.goalDrafts.count + 1
            let preset = smartPreset(for: category, rank: rank)
            let presetDate = Calendar.current.date(byAdding: .year, value: preset.years, to: Date())
            let newDraft = FinancialPlanningGoalDraft(
                name: name,
                category: category,
                targetDate: presetDate,
                targetAmount: preset.amount,
                priority: min(3, max(1, rank <= 2 ? 1 : rank <= 4 ? 2 : 3))
            )
            updated.goalDrafts.append(newDraft)
        }
        appState.updateFinancialPlanningJourney(updated)
    }

    private func addCustomGoal() {
        let name = customGoalName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        var updated = journey
        let rank = updated.goalDrafts.count + 1
        let preset = smartPreset(for: name, rank: rank)
        let presetDate = Calendar.current.date(byAdding: .year, value: preset.years, to: Date())
        updated.goalDrafts.append(FinancialPlanningGoalDraft(
            name: name,
            category: "Custom",
            targetDate: presetDate,
            targetAmount: preset.amount,
            priority: 2
        ))
        appState.updateFinancialPlanningJourney(updated)
        customGoalName = ""
    }

    private func updateGoalDraft(_ id: UUID, update: (inout FinancialPlanningGoalDraft) -> Void) {
        var updated = journey
        guard let index = updated.goalDrafts.firstIndex(where: { $0.id == id }) else { return }
        update(&updated.goalDrafts[index])
        appState.updateFinancialPlanningJourney(updated)
    }

    private func removeGoalDraft(_ id: UUID) {
        var updated = journey
        updated.goalDrafts.removeAll { $0.id == id }
        appState.updateFinancialPlanningJourney(updated)
    }

    private func movePriority(_ goalID: UUID, by offset: Int) {
        let currentOrder = priorityItems.map(\.id)
        guard let current = currentOrder.firstIndex(of: goalID) else { return }
        let target = min(max(current + offset, 0), currentOrder.count - 1)
        guard current != target else { return }
        var updated = journey
        var reordered = currentOrder
        let moved = reordered.remove(at: current)
        reordered.insert(moved, at: target)
        updated.goalPriorityIDs = reordered
        appState.updateFinancialPlanningJourney(updated)
    }

    // MARK: - Helper Methods & UI Wrappers
    private func journeySection<Content: View>(_ title: String, icon: String, tint: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(tint.opacity(0.12))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(tint)
                }
                Text(title)
                    .font(.headline.weight(.bold))
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        }
    }

    private func positionRow(_ title: String, value: String?) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value ?? "Not recorded")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(value == nil ? Color.secondary : Color.primary)
        }
        .padding(.vertical, 4)
    }

    private func goalTint(for category: String) -> Color {
        switch category {
        case "Marriage", "Wedding": return .pink
        case "Children": return .orange
        case "Build Wealth", "Wealth Creation": return .indigo
        case "Education": return .blue
        case "Home", "Home Purchase": return .green
        case "Vehicle": return .orange
        case "Travel", "Travel / Trip": return .cyan
        case "Retirement": return .purple
        case "Business Fund": return .teal
        default: return .blue
        }
    }

    private func goalIcon(for category: String) -> String {
        switch category {
        case "Marriage", "Wedding": return "heart.fill"
        case "Children": return "figure.2.and.child.holdinghands"
        case "Build Wealth", "Wealth Creation": return "chart.line.uptrend.xyaxis"
        case "Education": return "book.fill"
        case "Home", "Home Purchase": return "house.fill"
        case "Vehicle": return "car.fill"
        case "Travel", "Travel / Trip": return "airplane"
        case "Retirement": return "leaf.fill"
        case "Business Fund": return "briefcase.fill"
        default: return "target"
        }
    }

    private func priorityLabel(_ priority: Int) -> String {
        switch priority {
        case 1: return "High"
        case 3: return "Low"
        default: return "Medium"
        }
    }

    private func priorityColor(_ priority: Int) -> Color {
        switch priority {
        case 1: return .red
        case 3: return .green
        default: return .orange
        }
    }

    private func advance(to next: FinancialPlanningPhase) {
        var updated = journey
        updated.currentPhase = next
        appState.updateFinancialPlanningJourney(updated)
    }

    private var latestPlanningYear: Int? {
        let years = goals.map { Calendar.current.component(.year, from: $0.targetDate) }
            + journey.events.compactMap { $0.targetDate.map { Calendar.current.component(.year, from: $0) } }
            + journey.goalDrafts.compactMap { $0.targetDate.map { Calendar.current.component(.year, from: $0) } }
        guard let year = years.max(), year > Calendar.current.component(.year, from: Date()) else { return nil }
        return year
    }

    private func estimatedMonthlyNeed(for goal: AstraGoal) -> Double {
        let months = max(1, Calendar.current.dateComponents([.month], from: Date(), to: goal.targetDate).month ?? 1)
        return max(0, goal.targetAmount - goal.currentAmount) / Double(months)
    }
}

// MARK: - Goal Draft Quick Editor Sheet
private struct GoalDraftQuickEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: FinancialPlanningGoalDraft
    @State private var amountText: String
    let onSave: (FinancialPlanningGoalDraft) -> Void

    init(draft: FinancialPlanningGoalDraft, onSave: @escaping (FinancialPlanningGoalDraft) -> Void) {
        _draft = State(initialValue: draft)
        _amountText = State(initialValue: draft.targetAmount.map { String(format: "%.0f", $0) } ?? "")
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Details") {
                    TextField("Goal Name", text: $draft.name)
                    Picker("Priority", selection: $draft.priority) {
                        Text("High 🔥").tag(1)
                        Text("Medium ⚡️").tag(2)
                        Text("Low 🌿").tag(3)
                    }
                }

                Section("Timeline") {
                    DatePicker("Target Date", selection: Binding(
                        get: { draft.targetDate ?? Calendar.current.date(byAdding: .year, value: 3, to: Date())! },
                        set: { draft.targetDate = $0 }
                    ), displayedComponents: .date)
                }

                Section("Target Amount") {
                    TextField("Amount · try 25L or 1.5Cr", text: $amountText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Edit Milestone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let amt = parseFinancialAmount(amountText) {
                            draft.targetAmount = amt
                        }
                        onSave(draft)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Planning Assumption Enum
private enum PlanningAssumption: String, CaseIterable, Identifiable {
    case inflation
    case income
    case expenses
    case investmentReturn

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inflation: return "Annual Inflation Rate"
        case .income: return "Annual Income Growth"
        case .expenses: return "Annual Expense Growth"
        case .investmentReturn: return "Annual Portfolio Return"
        }
    }

    var detail: String {
        switch self {
        case .inflation: return "Applied to goal target purchasing power (India avg: 6%)"
        case .income: return "Expected annual salary / business growth (avg: 8-10%)"
        case .expenses: return "Annual cost of living escalations (avg: 5-7%)"
        case .investmentReturn: return "Estimated long-term blended equity/debt CAGR (10-12%)"
        }
    }

    var symbol: String {
        switch self {
        case .inflation: return "chart.line.uptrend.xyaxis"
        case .income: return "arrow.up.right"
        case .expenses: return "arrow.down.right"
        case .investmentReturn: return "chart.pie.fill"
        }
    }

    var tint: Color {
        switch self {
        case .inflation: return .orange
        case .income: return .green
        case .expenses: return .pink
        case .investmentReturn: return .blue
        }
    }

    var keyPath: WritableKeyPath<FinancialPlanningAssumptions, Double?> {
        switch self {
        case .inflation: return \.inflationRate
        case .income: return \.incomeGrowthRate
        case .expenses: return \.expenseGrowthRate
        case .investmentReturn: return \.investmentReturnRate
        }
    }
}

// MARK: - Assumption Value Editor
private struct AssumptionValueEditor: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    @State private var valueText: String
    let assumption: PlanningAssumption
    let value: Double?
    let onSave: (Double?) -> Void

    init(assumption: PlanningAssumption, value: Double?, onSave: @escaping (Double?) -> Void) {
        self.assumption = assumption
        self.value = value
        self.onSave = onSave
        _valueText = State(initialValue: value.map { String($0 * 100) } ?? "")
    }

    private var parsedValue: Double? {
        guard let number = Double(valueText), number.isFinite, (0...100).contains(number) else { return nil }
        return number / 100
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(assumption.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    TextField("Set", text: $valueText)
                        .keyboardType(.decimalPad)
                        .focused($isFocused)
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .multilineTextAlignment(.trailing)
                        .fixedSize()
                    Text("%")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))

                Text("Enter a value from 0% to 100%. This updates all future projections transparently.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .padding(22)
            .navigationTitle(assumption.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(parsedValue)
                        dismiss()
                    }
                    .disabled(parsedValue == nil)
                }
            }
        }
    }
}

// MARK: - Planning Event Editor
private struct PlanningEventEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var event: FinancialPlanningEvent
    @State private var estimatedCostText: String
    @State private var currentFundingText: String
    @State private var durationMonthsText: String
    @State private var showInvalidAmount = false
    let goals: [AstraGoal]
    let onSave: (FinancialPlanningEvent) -> Void

    init(event: FinancialPlanningEvent, goals: [AstraGoal], onSave: @escaping (FinancialPlanningEvent) -> Void) {
        _event = State(initialValue: event)
        _estimatedCostText = State(initialValue: event.currentEstimatedCost.map { String($0) } ?? "")
        _currentFundingText = State(initialValue: event.currentFunding.map { String($0) } ?? "")
        _durationMonthsText = State(initialValue: event.durationMonths.map { String($0) } ?? "")
        self.goals = goals
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Event Info") {
                    TextField("Event Name", text: $event.name)
                    Picker("Status", selection: $event.status) {
                        ForEach(PlanningEventStatus.allCases) { status in Text(status.rawValue).tag(status) }
                    }
                    Picker("Priority", selection: $event.priority) {
                        Text("High 🔥").tag(1)
                        Text("Medium ⚡️").tag(2)
                        Text("Low 🌿").tag(3)
                    }
                }

                Section("Timeline") {
                    Toggle("Set a target date", isOn: Binding(
                        get: { event.targetDate != nil },
                        set: { event.targetDate = $0 ? (event.targetDate ?? Date()) : nil }
                    ))
                    if event.targetDate != nil {
                        DatePicker("Target Date", selection: Binding(
                            get: { event.targetDate ?? Date() },
                            set: { event.targetDate = $0 }
                        ), displayedComponents: .date)
                    }
                }

                Section("Financials") {
                    TextField(event.frequency == .recurring ? "Estimated annual cost today" : "Estimated cost today", text: $estimatedCostText)
                        .keyboardType(.decimalPad)
                    TextField("Already saved for this event", text: $currentFundingText)
                        .keyboardType(.decimalPad)
                    Picker("Related Goal", selection: $event.linkedGoalID) {
                        Text("None").tag(UUID?.none)
                        ForEach(goals) { goal in Text(goal.goalName).tag(Optional(goal.id)) }
                    }
                    Picker("Frequency", selection: $event.frequency) {
                        ForEach(PlanningEventFrequency.allCases) { frequency in Text(frequency.rawValue).tag(frequency) }
                    }
                    Toggle("Fund event from investments in scenario", isOn: $event.fundingFromInvestments)
                }
            }
            .navigationTitle(event.name.isEmpty ? "New Life Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        event.name = event.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !event.name.isEmpty else { return }
                        event.currentEstimatedCost = parseFinancialAmount(estimatedCostText)
                        event.currentFunding = parseFinancialAmount(currentFundingText)
                        event.durationMonths = Int(durationMonthsText.trimmingCharacters(in: .whitespacesAndNewlines))
                        onSave(event)
                        dismiss()
                    }
                    .disabled(event.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
