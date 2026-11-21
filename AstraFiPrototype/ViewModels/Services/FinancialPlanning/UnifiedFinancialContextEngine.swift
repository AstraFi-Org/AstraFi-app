import Foundation

/// Metadata attached to existing profile-owned data. The profile remains the source of truth;
/// these records describe where a value came from and when it was last checked.
enum FinancialDataDomain: String, Codable, CaseIterable, Identifiable {
    case income, expenses, cashReserve, investments, liabilities, goals, household, preferences
    var id: String { rawValue }

    var title: String {
        switch self {
        case .income: "Income"
        case .expenses: "Monthly expenses"
        case .cashReserve: "Cash and emergency reserve"
        case .investments: "Investments"
        case .liabilities: "Loans and EMIs"
        case .goals: "Goals"
        case .household: "Household details"
        case .preferences: "Financial preferences"
        }
    }
}

enum FinancialDataSource: String, Codable {
    case assessment, cashFlowUpdate, userConfirmed, imported, estimated, calculated
}

struct FinancialDataFreshnessRecord: Codable, Equatable, Identifiable {
    var domain: FinancialDataDomain
    var source: FinancialDataSource
    var lastUpdatedAt: Date
    var lastVerifiedAt: Date?
    var confidence: Double?
    var id: String { domain.rawValue }
}

enum FinancialDecisionPurpose: String, Codable {
    case fixedIncomeMaturity, investmentContribution, debtDecision, retirementWithdrawal, generalPlanning
}

struct FinancialReverificationPrompt: Identifiable, Equatable {
    let domain: FinancialDataDomain
    let currentValueDescription: String
    let reason: String
    var id: String { domain.rawValue }
}

enum FinancialJourneyEventKind: String, Codable {
    case actual, projected, decisionRequired
}

struct UnifiedFinancialJourneyEvent: Identifiable, Equatable {
    let id: UUID
    let title: String
    let detail: String
    let date: Date?
    let amount: Double?
    let kind: FinancialJourneyEventKind
    let sourceDomain: FinancialDataDomain
}

struct UnifiedFinancialContext: Equatable {
    let position: FinancialPositionSummary
    let emergencyReserveGap: Double
    let highCostDebtAmount: Double
    let upcomingGoals: [AstraGoal]
    let totalInvestmentValue: Double
    let monthlySurplusAfterEmis: Double?
    let missingDomains: [FinancialDataDomain]
}

/// Immutable what-if branch record. It captures the profile inputs and assumptions used so
/// later profile edits do not silently rewrite a previously explored scenario.
struct FinancialPlanningScenarioBranch: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var createdAt: Date = Date()
    var horizonYear: Int
    var baselineMonthlyContribution: Double
    var scenarioMonthlyContribution: Double
    var baselineEndingInvestments: Double
    var scenarioEndingInvestments: Double
    var assumptions: FinancialPlanningAssumptions
    var monthlyIncomeAtSave: Double
    var monthlyExpensesAtSave: Double
    var monthlyEMIAtSave: Double
    var reserveAtSave: Double
    var startingInvestmentsAtSave: Double
    var plannedEventsAtSave: [FinancialPlanningEvent]
    var goalsAtSave: [FinancialScenarioGoalSnapshot]
}

struct FinancialScenarioGoalSnapshot: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var targetDate: Date
}

/// Deterministic profile interpretation for plans and decision screens. It intentionally
/// consumes the existing profile and does not collect or persist duplicate financial values.
enum UnifiedFinancialContextEngine {
    static let defaultFreshnessWindowDays = 180

    static func build(profile: AstraUserProfile?) -> UnifiedFinancialContext {
        let position = FinancialPlanningEngine.currentPosition(profile: profile)
        guard let profile else {
            return UnifiedFinancialContext(position: position, emergencyReserveGap: 0, highCostDebtAmount: 0,
                                           upcomingGoals: [], totalInvestmentValue: 0,
                                           monthlySurplusAfterEmis: nil,
                                           missingDomains: [.income, .expenses, .cashReserve, .investments, .liabilities, .goals])
        }
        let target = position.emergencyTarget ?? 0
        let reserve = position.emergencyReserve ?? 0
        let highCostDebt = profile.loans.filter { $0.interestRate >= 10 }
            .reduce(0) { $0 + max(0, $1.loanAmount) }
        let upcomingGoals = profile.goals.filter { $0.targetDate >= Calendar.current.startOfDay(for: Date()) }
            .sorted { $0.targetDate < $1.targetDate }
        var missing: [FinancialDataDomain] = []
        if position.monthlyIncome == nil { missing.append(.income) }
        if position.monthlyExpenses == nil { missing.append(.expenses) }
        if position.emergencyReserve == nil { missing.append(.cashReserve) }
        if profile.investments.isEmpty { missing.append(.investments) }
        if profile.loans.isEmpty { missing.append(.liabilities) }
        if profile.goals.isEmpty { missing.append(.goals) }
        return UnifiedFinancialContext(
            position: position,
            emergencyReserveGap: max(0, target - reserve),
            highCostDebtAmount: highCostDebt,
            upcomingGoals: upcomingGoals,
            totalInvestmentValue: profile.investments.reduce(0) { $0 + max(0, $1.currentValue.safeFinite) },
            monthlySurplusAfterEmis: position.monthlySurplus,
            missingDomains: missing
        )
    }

    /// Only asks about values needed by this decision and only when their known verification
    /// date is outside the freshness window. Missing values are reported separately by context.
    static func reverificationPrompts(
        profile: AstraUserProfile?,
        purpose: FinancialDecisionPurpose,
        today: Date = Date(),
        freshnessWindowDays: Int = defaultFreshnessWindowDays
    ) -> [FinancialReverificationPrompt] {
        guard let profile else { return [] }
        let required: [FinancialDataDomain]
        switch purpose {
        case .fixedIncomeMaturity: required = [.expenses, .cashReserve, .goals, .liabilities]
        case .investmentContribution: required = [.income, .expenses, .cashReserve, .goals]
        case .debtDecision: required = [.income, .expenses, .liabilities, .cashReserve]
        case .retirementWithdrawal: required = [.expenses, .investments, .goals, .household]
        case .generalPlanning: required = [.income, .expenses, .cashReserve, .investments, .liabilities, .goals]
        }
        let records = Dictionary(uniqueKeysWithValues: (profile.financialDataFreshness ?? []).map { ($0.domain, $0) })
        let ageLimit = max(1, freshnessWindowDays)
        return required.compactMap { domain in
            guard hasMaterialValue(domain, in: profile) else { return nil }
            let verifiedDate = records[domain]?.lastVerifiedAt
            guard let verifiedDate else { return nil } // Legacy profiles are not interrupted without verification history.
            let ageDays = Calendar.current.dateComponents([.day], from: verifiedDate, to: today).day ?? 0
            guard ageDays >= ageLimit else { return nil }
            return FinancialReverificationPrompt(
                domain: domain,
                currentValueDescription: valueDescription(domain, profile: profile),
                reason: "This detail was last confirmed \(ageDays) days ago and affects this scenario."
            )
        }
    }

    static func journeyEvents(profile: AstraUserProfile?, journey: FinancialPlanningJourney?, today: Date = Date()) -> [UnifiedFinancialJourneyEvent] {
        guard let profile else { return [] }
        let goals = profile.goals.compactMap { goal -> UnifiedFinancialJourneyEvent? in
            guard goal.targetDate >= Calendar.current.startOfDay(for: today) else { return nil }
            return UnifiedFinancialJourneyEvent(id: goal.id, title: goal.goalName,
                detail: "Goal target · \(goal.targetAmount.toCurrency())", date: goal.targetDate,
                amount: goal.targetAmount, kind: .projected, sourceDomain: .goals)
        }
        let planned = (journey?.events ?? []).compactMap { event -> UnifiedFinancialJourneyEvent? in
            guard let date = event.targetDate, date >= Calendar.current.startOfDay(for: today) else { return nil }
            return UnifiedFinancialJourneyEvent(id: event.id, title: event.name,
                detail: "\(event.status.rawValue) · planned financial event", date: date,
                amount: event.currentEstimatedCost, kind: .projected, sourceDomain: .goals)
        }
        let loanEndings = profile.loans.compactMap { loan -> UnifiedFinancialJourneyEvent? in
            let remainingMonths = max(0, loan.loanTenureMonths - loan.installmentsPaid)
            guard remainingMonths > 0,
                  let date = Calendar.current.date(byAdding: .month, value: remainingMonths, to: today) else { return nil }
            return UnifiedFinancialJourneyEvent(id: loan.id, title: "\(loan.displayName) may finish",
                detail: "Projected from recorded tenure and paid installments", date: date,
                amount: loan.loanAmount, kind: .decisionRequired, sourceDomain: .liabilities)
        }
        return (goals + planned + loanEndings).sorted { ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture) }
    }

    static func maturityDecisionSummary(profile: AstraUserProfile?, proceeds: Double) -> [String] {
        let context = build(profile: profile)
        var points: [String] = []
        if context.emergencyReserveGap > 0 {
            points.append("Your recorded emergency reserve is about \(context.emergencyReserveGap.toCurrency()) below its target.")
        }
        if let goal = context.upcomingGoals.first {
            let months = max(0, Calendar.current.dateComponents([.month], from: Date(), to: goal.targetDate).month ?? 0)
            points.append("Your next recorded goal is \(goal.goalName), about \(months) months away.")
        }
        if context.highCostDebtAmount > 0 {
            points.append("Your profile records \(context.highCostDebtAmount.toCurrency()) of loans at 10% or higher; compare prepayment and liquidity scenarios.")
        }
        if points.isEmpty && proceeds > 0 {
            points.append("No near-term reserve gap, upcoming goal, or 10%+ loan is recorded. Compare cash and reinvestment scenarios using your own horizon.")
        }
        return points
    }

    static func makeContributionBranch(
        profile: AstraUserProfile?,
        journey: FinancialPlanningJourney,
        monthlyContribution: Double,
        throughYear: Int,
        name: String? = nil,
        today: Date = Date()
    ) -> FinancialPlanningScenarioBranch? {
        guard monthlyContribution.isFinite, monthlyContribution >= 0,
              let profile else { return nil }
        let position = FinancialPlanningEngine.currentPosition(profile: profile)
        guard
              let income = position.monthlyIncome, let expenses = position.monthlyExpenses,
              let baselineContribution = position.monthlyInvestmentContribution else { return nil }
        var branchJourney = journey
        branchJourney.monthlyInvestmentWhatIf = monthlyContribution
        guard let branchRows = FinancialPlanningEngine.projection(profile: profile, journey: branchJourney,
                                                                    throughYear: throughYear, today: today),
              let baselineRows = FinancialPlanningEngine.projection(profile: profile, journey: journey,
                                                                     throughYear: throughYear, today: today),
              let branchEnding = branchRows.last?.investmentBalance,
              let baselineEnding = baselineRows.last?.currentPathInvestmentBalance else { return nil }
        return FinancialPlanningScenarioBranch(
            name: name ?? "Monthly contribution · \(monthlyContribution.toCurrency())",
            horizonYear: throughYear,
            baselineMonthlyContribution: baselineContribution,
            scenarioMonthlyContribution: monthlyContribution,
            baselineEndingInvestments: baselineEnding,
            scenarioEndingInvestments: branchEnding,
            assumptions: journey.assumptions,
            monthlyIncomeAtSave: income,
            monthlyExpensesAtSave: expenses,
            monthlyEMIAtSave: position.monthlyDebtPayments ?? 0,
            reserveAtSave: position.emergencyReserve ?? 0,
            startingInvestmentsAtSave: position.investments ?? 0,
            plannedEventsAtSave: journey.events,
            goalsAtSave: profile.goals.map {
                FinancialScenarioGoalSnapshot(id: $0.id, name: $0.goalName,
                    targetAmount: $0.targetAmount, currentAmount: $0.currentAmount, targetDate: $0.targetDate)
            }
        )
    }

    private static func hasMaterialValue(_ domain: FinancialDataDomain, in profile: AstraUserProfile) -> Bool {
        switch domain {
        case .income: profile.basicDetails.monthlyIncome > 0 || profile.basicDetails.monthlyIncomeAfterTax > 0
        case .expenses: profile.basicDetails.monthlyExpenses > 0
        case .cashReserve: profile.basicDetails.emergencyFundAmount > 0
        case .investments: !profile.investments.isEmpty
        case .liabilities: !profile.loans.isEmpty
        case .goals: !profile.goals.isEmpty
        case .household: profile.basicDetails.age > 0 || profile.basicDetails.adultDependents + profile.basicDetails.childDependents > 0
        case .preferences: true
        }
    }

    private static func valueDescription(_ domain: FinancialDataDomain, profile: AstraUserProfile) -> String {
        switch domain {
        case .income: "₹\(Int(profile.basicDetails.monthlyIncomeAfterTax > 0 ? profile.basicDetails.monthlyIncomeAfterTax : profile.basicDetails.monthlyIncome).formatted())/month"
        case .expenses: "₹\(Int(profile.basicDetails.monthlyExpenses).formatted())/month"
        case .cashReserve: "₹\(Int(profile.basicDetails.emergencyFundAmount).formatted())"
        case .investments: "\(profile.investments.count) recorded investments"
        case .liabilities: "\(profile.loans.count) recorded loans"
        case .goals: "\(profile.goals.count) recorded goals"
        case .household: "\(profile.basicDetails.adultDependents + profile.basicDetails.childDependents) dependents"
        case .preferences: "\(profile.basicDetails.riskTolerance.rawValue) risk preference"
        }
    }
}
