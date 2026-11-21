import Foundation

/// Illustrative planning scenarios. These are assumptions, not predictions.
enum PlanningScenarioKind: String, Codable, CaseIterable, Identifiable {
    case optimistic = "Optimistic"
    case base = "Base"
    case conservative = "Conservative"
    case stress = "Stress"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .optimistic: return "Lower inflation, higher growth"
        case .base: return "Core planning assumption"
        case .conservative: return "More cautious rates"
        case .stress: return "Higher inflation, lower returns"
        }
    }

    var disclaimer: String {
        "Illustrative projection using planning assumptions, not a guaranteed outcome."
    }

    static func assumptionSet(for kind: PlanningScenarioKind) -> FinancialPlanningAssumptions {
        switch kind {
        case .optimistic:
            return FinancialPlanningAssumptions(
                version: 1,
                enteredAt: nil,
                inflationRate: 0.04,
                incomeGrowthRate: 0.10,
                expenseGrowthRate: 0.04,
                investmentReturnRate: 0.12,
                source: "Planning assumption · Optimistic",
                annualSIPStepUpRate: 0.10,
                postRetirementReturnRate: 0.07,
                retirementWithdrawalRate: 0.04,
                healthcareInflationRate: 0.06,
                housingInflationRate: 0.05,
                educationInflationRate: 0.07,
                lifestyleInflationRate: 0.04,
                travelInflationRate: 0.05,
                scenarioKind: .optimistic
            )
        case .base:
            return FinancialPlanningAssumptions(
                version: 1,
                enteredAt: nil,
                inflationRate: 0.05,
                incomeGrowthRate: 0.08,
                expenseGrowthRate: 0.05,
                investmentReturnRate: 0.105,
                source: "Planning assumption · Base",
                annualSIPStepUpRate: 0.10,
                postRetirementReturnRate: 0.06,
                retirementWithdrawalRate: 0.04,
                healthcareInflationRate: 0.08,
                housingInflationRate: 0.06,
                educationInflationRate: 0.08,
                lifestyleInflationRate: 0.05,
                travelInflationRate: 0.06,
                scenarioKind: .base
            )
        case .conservative:
            return FinancialPlanningAssumptions(
                version: 1,
                enteredAt: nil,
                inflationRate: 0.06,
                incomeGrowthRate: 0.06,
                expenseGrowthRate: 0.06,
                investmentReturnRate: 0.09,
                source: "Planning assumption · Conservative",
                annualSIPStepUpRate: 0.08,
                postRetirementReturnRate: 0.05,
                retirementWithdrawalRate: 0.035,
                healthcareInflationRate: 0.08,
                housingInflationRate: 0.07,
                educationInflationRate: 0.09,
                lifestyleInflationRate: 0.06,
                travelInflationRate: 0.07,
                scenarioKind: .conservative
            )
        case .stress:
            return FinancialPlanningAssumptions(
                version: 1,
                enteredAt: nil,
                inflationRate: 0.07,
                incomeGrowthRate: 0.05,
                expenseGrowthRate: 0.07,
                investmentReturnRate: 0.075,
                source: "Planning assumption · Stress",
                annualSIPStepUpRate: 0.05,
                postRetirementReturnRate: 0.04,
                retirementWithdrawalRate: 0.035,
                healthcareInflationRate: 0.09,
                housingInflationRate: 0.08,
                educationInflationRate: 0.10,
                lifestyleInflationRate: 0.07,
                travelInflationRate: 0.08,
                scenarioKind: .stress
            )
        }
    }
}

enum FinancialGoalType: String, Codable, CaseIterable, Identifiable {
    case retirement = "Retirement"
    case education = "Education"
    case marriage = "Marriage"
    case home = "Home"
    case vehicle = "Vehicle"
    case travel = "Travel"
    case healthcare = "Healthcare"
    case custom = "Custom"

    var id: String { rawValue }
}

enum PlanFeasibility: String, Codable, CaseIterable, Identifiable {
    case healthy = "Healthy"
    case manageable = "Manageable"
    case aggressive = "Aggressive"
    case notCurrentlyFeasible = "Not currently feasible"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .healthy: return "checkmark.seal.fill"
        case .manageable: return "equal.circle.fill"
        case .aggressive: return "exclamationmark.triangle.fill"
        case .notCurrentlyFeasible: return "xmark.octagon.fill"
        }
    }

    var summary: String {
        switch self {
        case .healthy: return "Your current surplus can support this plan."
        case .manageable: return "This plan uses most of your current surplus."
        case .aggressive: return "This plan requires a higher contribution than your current surplus."
        case .notCurrentlyFeasible: return "This plan is not currently feasible from monthly surplus alone."
        }
    }
}

/// Goal-agnostic planning input. Fields are optional so education, marriage, and retirement can share the engine.
struct FinancialGoalConfiguration: Codable, Equatable, Identifiable {
    var id: UUID
    var goalType: FinancialGoalType
    var goalName: String
    var targetAmountToday: Double?
    var currentAge: Int?
    var goalAge: Int?
    var yearsToGoal: Int?
    var currentMonthlyIncome: Double?
    var currentMonthlyExpenses: Double?
    /// Today's household lifestyle cost used specifically to price a retirement goal.
    var retirementLifestyleExpensesToday: Double?
    var currentMonthlyHealthcareExpenses: Double?
    var currentSavings: Double?
    var currentInvestments: Double?
    var startingMonthlyInvestment: Double?
    var annualInvestmentStepUp: Double?
    var retirementAge: Int?
    var lifeExpectancy: Int?
    var retirementWithdrawalRate: Double?
    var existingGoalCorpus: Double?
    var priority: Int?
    var otherGoalMonthlyAllocations: Double?
    var otherMonthlyRetirementIncome: Double?
    var healthcareReserveToday: Double?

    init(
        id: UUID = UUID(),
        goalType: FinancialGoalType,
        goalName: String,
        targetAmountToday: Double? = nil,
        currentAge: Int? = nil,
        goalAge: Int? = nil,
        yearsToGoal: Int? = nil,
        currentMonthlyIncome: Double? = nil,
        currentMonthlyExpenses: Double? = nil,
        retirementLifestyleExpensesToday: Double? = nil,
        currentMonthlyHealthcareExpenses: Double? = nil,
        currentSavings: Double? = nil,
        currentInvestments: Double? = nil,
        startingMonthlyInvestment: Double? = nil,
        annualInvestmentStepUp: Double? = nil,
        retirementAge: Int? = nil,
        lifeExpectancy: Int? = nil,
        retirementWithdrawalRate: Double? = nil,
        existingGoalCorpus: Double? = nil,
        priority: Int? = nil,
        otherGoalMonthlyAllocations: Double? = nil,
        otherMonthlyRetirementIncome: Double? = nil,
        healthcareReserveToday: Double? = nil
    ) {
        self.id = id
        self.goalType = goalType
        self.goalName = goalName
        self.targetAmountToday = targetAmountToday
        self.currentAge = currentAge
        self.goalAge = goalAge
        self.yearsToGoal = yearsToGoal
        self.currentMonthlyIncome = currentMonthlyIncome
        self.currentMonthlyExpenses = currentMonthlyExpenses
        self.retirementLifestyleExpensesToday = retirementLifestyleExpensesToday
        self.currentMonthlyHealthcareExpenses = currentMonthlyHealthcareExpenses
        self.currentSavings = currentSavings
        self.currentInvestments = currentInvestments
        self.startingMonthlyInvestment = startingMonthlyInvestment
        self.annualInvestmentStepUp = annualInvestmentStepUp
        self.retirementAge = retirementAge
        self.lifeExpectancy = lifeExpectancy
        self.retirementWithdrawalRate = retirementWithdrawalRate
        self.existingGoalCorpus = existingGoalCorpus
        self.priority = priority
        self.otherGoalMonthlyAllocations = otherGoalMonthlyAllocations
        self.otherMonthlyRetirementIncome = otherMonthlyRetirementIncome
        self.healthcareReserveToday = healthcareReserveToday
    }

    var resolvedYearsToGoal: Int? {
        if let yearsToGoal, yearsToGoal > 0 { return yearsToGoal }
        if let currentAge, let goalAge, goalAge > currentAge { return goalAge - currentAge }
        if let currentAge, let retirementAge, retirementAge > currentAge { return retirementAge - currentAge }
        return nil
    }
}

struct ExplanationStep: Codable, Equatable, Identifiable {
    var id: String
    var label: String
    var value: String
}

struct FinancialNumberExplanation: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var resultValue: Double
    var resultLabel: String
    var steps: [ExplanationStep]
    var footnote: String
}

struct RetirementYearSnapshot: Codable, Equatable, Identifiable {
    var age: Int
    var beginningCorpus: Double
    var investmentReturnAmount: Double
    var lifestyleExpense: Double
    var healthcareExpense: Double
    var otherIncome: Double
    var endingCorpus: Double

    var id: Int { age }
}

struct CashflowProjectionYear: Codable, Equatable, Identifiable {
    var age: Int
    var yearOffset: Int
    var monthlyIncome: Double
    var monthlyExpenses: Double
    var monthlyHealthcare: Double
    var monthlySurplus: Double
    var monthlyContribution: Double
    var lifeEventCostMonthly: Double
    var otherGoalAllocation: Double
    var investmentCorpus: Double
    var goalProgress: Double
    var isRetirementYear: Bool

    var id: Int { yearOffset }
}

struct PlanFeasibilityResult: Codable, Equatable {
    var status: PlanFeasibility
    var requiredStartingSIP: Double
    var availableMonthlySurplus: Double
    var recommendedSIPStepUp: Double
    var selectedSIPStepUp: Double
    var adjustmentSuggestions: [String]
    var notes: [String]
}

struct GoalProjectionResult: Codable, Equatable {
    var goalType: FinancialGoalType
    var goalName: String
    var scenario: PlanningScenarioKind
    var assumptions: ResolvedPlanningAssumptions
    var yearsToGoal: Int
    var presentValue: Double
    var futureValue: Double
    var existingInvestmentsToday: Double
    var futureValueOfExistingInvestments: Double
    var requiredCorpus: Double
    var fundingGap: Double
    var requiredStartingSIP: Double
    var selectedStartingSIP: Double
    var projectedCorpusFromPlan: Double
    var feasibility: PlanFeasibilityResult
    var yearlyProjection: [CashflowProjectionYear]
    var explanations: [FinancialNumberExplanation]
    var validationMessages: [String]
    var retirement: RetirementProjectionResult?
}

struct RetirementProjectionResult: Codable, Equatable {
    var currentAge: Int
    var retirementAge: Int
    var lifeExpectancy: Int
    var yearsToRetirement: Int
    var yearsInRetirement: Int
    var monthlyLifestyleToday: Double
    var monthlyHealthcareToday: Double
    var estimatedMonthlyLifestyleAtRetirement: Double
    var estimatedMonthlyHealthcareAtRetirement: Double
    var requiredCorpus: Double
    var withdrawalRateCorpus: Double
    var usedYearByYearSimulation: Bool
    var drawdown: [RetirementYearSnapshot]
}

struct ScenarioComparisonRow: Codable, Equatable, Identifiable {
    var scenario: PlanningScenarioKind
    var futureGoalValue: Double
    var retirementMonthlyExpense: Double?
    var requiredCorpus: Double
    var requiredStartingSIP: Double
    var projectedCorpus: Double
    var fundingGap: Double

    var id: String { scenario.rawValue }
}

struct PlanningValidationIssue: Codable, Equatable, Identifiable {
    var id: String
    var message: String
    var isBlocking: Bool
}
