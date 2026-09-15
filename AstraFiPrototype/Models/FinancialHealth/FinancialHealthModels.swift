import Foundation

enum FinancialHealthSeverity: String, Codable, Hashable {
    case critical, high, medium, low, none
}

enum FinancialHealthPriorityLevel: String, Codable, Hashable {
    case critical, high, medium, low
}

enum FinancialHealthActionDestination: String, Hashable {
    case emergencyPlanner
    case loanTracker
    case investments
    case protection
    case goals
    case vitals
}

struct FinancialHealthMetric: Identifiable, Hashable {
    let id: String
    let label: String
    let value: String
}

struct FinancialHealthParameterResult: Identifiable, Hashable {
    var id: AssessmentParameter { parameter }
    let parameter: AssessmentParameter
    let score: Double
    let scoreOutOf10: Double
    let isAssessed: Bool
    let status: AssessmentParameterStatus
    let statusTitle: String
    let severity: FinancialHealthSeverity
    let metrics: [FinancialHealthMetric]
    let whyItMatters: String
    let financialImpact: String
    let recommendedAction: String
    let affectedAreas: [String]
    let oneLineReason: String
    let priority: FinancialHealthPriorityLevel
    let improvementPotential: Double
    let actionTitle: String
    let actionDestination: FinancialHealthActionDestination
    let contributionPoints: Double
    let possiblePoints: Double

    var displayScore: String {
        isAssessed ? String(format: "%.1f / 10", scoreOutOf10) : "Needs information"
    }

    var weightPercent: Int {
        (FinancialHealthWeights.weight(for: parameter) * 100).rounded().safeInt
    }

    var contributionSentence: String {
        guard isAssessed else {
            return "This area still needs information, so it is not treated as poor financial health."
        }
        let current = contributionPoints.rounded().safeInt
        let possible = possiblePoints.rounded().safeInt
        return "\(parameter.title) currently contributes \(current)/\(possible) possible points to your overall score."
    }
}

struct FinancialHealthPriorityItem: Identifiable, Hashable {
    let id: String
    let rank: Int
    let parameter: AssessmentParameter
    let title: String
    let reason: String
    let impact: String
    let currentValue: String
    let targetValue: String
    let actionTitle: String
    let destination: FinancialHealthActionDestination
}

struct FinancialHealthWhatIfScenario: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let currentScore: Int
    let estimatedScore: Int

    var delta: Int { estimatedScore - currentScore }
}

struct FinancialHealthGoalReadiness: Identifiable, Hashable {
    let id: UUID
    let name: String
    let targetAmount: Double
    let currentAmount: Double
    let monthlyContribution: Double
    let projectedCompletion: String
    let status: String
    let progress: Double
}

struct FinancialHealthJourneyPoint: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let score: Int
    let label: String
}

struct FinancialHealthReportModel: Hashable {
    let insights: FinancialAssessmentInsights
    let overallScore: Double
    let overallScoreInt: Int
    let statusTitle: String
    let previousScore: Int?
    let scoreChange: Int?
    let parameters: [FinancialHealthParameterResult]
    let priorities: [FinancialHealthPriorityItem]
    let whatIfScenarios: [FinancialHealthWhatIfScenario]
    let goals: [FinancialHealthGoalReadiness]
    let journey: [FinancialHealthJourneyPoint]
    let journeyGain: Int?
    let nextSteps: [FinancialHealthPriorityItem]

    func result(for parameter: AssessmentParameter) -> FinancialHealthParameterResult? {
        parameters.first { $0.parameter == parameter }
    }

    var radarValues: [(String, Double, Double)] {
        FinancialHealthEngine.radarValues(from: parameters)
    }
}

struct FinancialHealthSnapshot: Hashable {
    var monthlyIncome: Double
    var grossMonthlyIncome: Double
    var monthlyExpenses: Double
    var monthlySurplus: Double
    var savingsRate: Double
    var expenseRatio: Double
    var incomeStability: Double?
    var vitalsAssessed: Bool
    var hasFixedIncome: Bool

    var emergencyFundAmount: Double
    var emergencyFundAssessed: Bool
    var essentialMonthlyExpenses: Double
    var emergencyMonthlyNeed: Double
    var emergencyTarget: Double
    var emergencyCoverageMonths: Double
    var emergencyGap: Double
    var emergencyTargetIsEstimate: Bool

    var loanCount: Int
    var totalMonthlyEMI: Double
    var outstandingDebt: Double
    var debtToIncomeRatio: Double
    var emiToSurplusRatio: Double
    var hasHighRiskDebt: Bool
    var highInterestDebtAmount: Double
    var remainingInterestEstimate: Double?
    var debtFreeDate: Date?

    var investmentBreakdown: InvestmentRiskBreakdown
    var investmentCount: Int
    var uniqueInvestmentCategories: Int
    var monthlyInvestmentContribution: Double
    var investmentAssessed: Bool
    var goalTargetTotal: Double
    var goalCurrentTotal: Double

    var insuranceCount: Int
    var hasHealthInsurance: Bool
    var hasLifeInsurance: Bool
    var adultDependents: Int
    var childDependents: Int
    var totalProtectionCoverage: Double
    var insuranceAssessed: Bool
    var annualInsurancePremium: Double = 0
    var insurancePremiumToIncome: Double? = nil
    var insurancePremiumToSurplus: Double? = nil
    var estimatedProtectionNeed: Double? = nil
    var lifeProtectionGap: Double? = nil

    var lowInvestmentBufferMonths: Double { 6.0 }
}
