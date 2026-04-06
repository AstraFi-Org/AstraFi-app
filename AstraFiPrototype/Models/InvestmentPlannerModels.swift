import Foundation
import SwiftUI

struct PortfolioBlueprint: Codable, Equatable {
    var allocations: [AssetAllocation]
    var blendedCAGR: Double           
    var riskLabel: String
}

struct PortfolioAsset: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var monthlyInvestment: Double
    var expectedValue: Double
    var riskLevel: AstraRiskLevel
}

struct AssetAllocation: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var percentage: Double
    var expectedCAGR: Double
    var riskLevel: AstraRiskLevel

    init(id: UUID = UUID(), name: String, percentage: Double, expectedCAGR: Double, riskLevel: AstraRiskLevel) {
        self.id = id
        self.name = name
        self.percentage = percentage
        self.expectedCAGR = expectedCAGR
        self.riskLevel = riskLevel
    }
}

enum AstraRiskLevel: String, Codable, CaseIterable { case low, mid, high }
enum AstraLiquidityLevel: String, Codable, CaseIterable { case high, mid, low }

enum EMIFrequency: String, Codable, CaseIterable {
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case halfYearly = "Half-Yearly"
    case yearly = "Yearly"

    var paymentsPerYear: Double {
        switch self {
        case .monthly: return 12
        case .quarterly: return 4
        case .halfYearly: return 2
        case .yearly: return 1
        }
    }
}

enum InterestType: String, Codable, CaseIterable {
    case simple = "Simple"
    case compounded = "Compounded"
}

struct PlanScenario: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var cagr: Double
    var gainLoss: Double
    var finalValue: Double

    init(id: UUID = UUID(), name: String, cagr: Double, gainLoss: Double, finalValue: Double) {
        self.id = id
        self.name = name
        self.cagr = cagr
        self.gainLoss = gainLoss
        self.finalValue = finalValue
    }
}

struct FeasibilityResult: Codable, Equatable {
    var isAffordable: Bool
    var disposableIncome: Double
    var sipToIncomeRatio: Double
    var warning: String?
}

struct Plan1Result: Codable, Equatable {
    var name: String = "Pure Investment"
    var subtitle: String = "Focused on long-term wealth"
    var icon: String = "star.circle.fill"
    var totalInvested: Double
    var projectedValue: Double
    var lumpsumContribution: Double
    var sipContribution: Double
    var portfolio: PortfolioBlueprint
    var scenarios: [PlanScenario]
    var reachesGoal: Bool
    var shortfall: Double
    var sipPerAsset: [String: Double]
    var tenure: Int = 1
    var highlights: [String]

    var assets: [PortfolioAsset] {
        portfolio.allocations.map { allocation in
            let monthly = sipPerAsset[allocation.name] ?? 0

            let r = allocation.expectedCAGR / 100 / 12
            let m = Double(tenure * 12)
            let fv = r > 0 ? monthly * (pow(1+r, m) - 1) / r * (1+r) : monthly * m

            return PortfolioAsset(
                id: allocation.id,
                name: allocation.name,
                monthlyInvestment: monthly,
                expectedValue: fv,
                riskLevel: allocation.riskLevel
            )
        }
    }
}

struct Plan2Result: Codable, Equatable {
    var name: String = "Loan Strategy"
    var subtitle: String = "Own asset now via loan"
    var icon: String = "car.circle.fill"
    var loanAmount: Double
    var loanRate: Double
    var monthlyEMI: Double
    var totalAmountPaid: Double
    var totalInterestPaid: Double
    var monthlySIPKept: Double
    var sipReturns: Double
    var investmentProfit: Double
    var netWealthGain: Double
    var totalMonthlyCommitment: Double
    var roi: Double
    var reachesGoal: Bool
    var shortfall: Double
    var breakdown: [PlanBreakdownItem]
    var highlights: [String]
    var yearlyBreakdown: [Plan2YearlyDetail] = []

    static func empty() -> Plan2Result {
        return Plan2Result(loanAmount: 0, loanRate: 0, monthlyEMI: 0, totalAmountPaid: 0,
                           totalInterestPaid: 0, monthlySIPKept: 0, sipReturns: 0,
                           investmentProfit: 0, netWealthGain: 0, totalMonthlyCommitment: 0,
                           roi: 0, reachesGoal: false, shortfall: 0, breakdown: [], highlights: [],
                           yearlyBreakdown: [])
    }
}

struct Plan2YearlyDetail: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let year: Int
    let date: Date
    let emiPaidYearly: Double
    let sipInvestedYearly: Double
    let remainingPrincipal: Double
    let totalPortfolioValue: Double
}

struct LeveragedStrategyResult: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var finalValue: Double
    var totalEMIPaid: Double
    var netProfit: Double
    var breakEvenReturn: Double
    var riskLevel: String
    var riskFlags: [String]
    var survivalDuration: Int? 
    var yearlyBreakdown: [Plan3YearlyDetail]
    var milestones: [Plan3Milestone] = []
}

struct Plan3Milestone: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let label: String
    let startValue: Double
    let growth: Double
    let emiPaid: Double 
    let endValue: Double
}

struct LeveragedScenarioAnalysis: Codable, Equatable {
    var bestCaseReturn: Double
    var worstCaseReturn: Double
    var realisticCaseReturn: Double
}

struct Plan3Result: Codable, Equatable {
    var name: String = "Leveraged Investing"
    var subtitle: String = "Evaluate loan-based investment strategies"
    var icon: String = "arrow.up.right.circle.fill"

    var loanAmount: Double
    var loanRate: Double
    var tenure: Int
    var monthlyEMI: Double

    var conservative: LeveragedStrategyResult
    var moderate: LeveragedStrategyResult
    var aggressive: LeveragedStrategyResult

    var recommendedStrategy: String
    var recommendationReason: String
    var scenarios: LeveragedScenarioAnalysis
    var portfolio: PortfolioBlueprint? 

    static func empty() -> Plan3Result {
        let emptyStrategy = LeveragedStrategyResult(name: "", description: "", finalValue: 0, totalEMIPaid: 0, netProfit: 0, breakEvenReturn: 0, riskLevel: "", riskFlags: [], survivalDuration: nil, yearlyBreakdown: [])
        return Plan3Result(loanAmount: 0, loanRate: 0, tenure: 1, monthlyEMI: 0,
                           conservative: emptyStrategy, moderate: emptyStrategy, aggressive: emptyStrategy,
                           recommendedStrategy: "", recommendationReason: "",
                           scenarios: LeveragedScenarioAnalysis(bestCaseReturn: 0, worstCaseReturn: 0, realisticCaseReturn: 0),
                           portfolio: nil)
    }
}

struct Plan3MonthlyStep: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let month: String
    let startValue: Double
    let investment: Double
    let growth: Double
    let interestPaid: Double
    let emiFromPocket: Double
    let endValue: Double
    var loanOutstanding: Double = 0
}

struct Plan3YearlyDetail: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let year: Int
    let date: Date
    let startValue: Double
    let investmentValue: Double
    let emiPaidYearly: Double
    let withdrawalYearly: Double
    let netYearlyProfit: Double
    var monthlySteps: [Plan3MonthlyStep] = []
}

struct PlanBreakdownItem: Identifiable, Codable, Equatable {
    let id: UUID
    var label: String
    var icon: String
    var value: Double
    var isNegative: Bool

    init(id: UUID = UUID(), label: String, icon: String, value: Double, isNegative: Bool) {
        self.id = id
        self.label = label
        self.icon = icon
        self.value = value
        self.isNegative = isNegative
    }
}

struct PlanRecommendations: Codable, Equatable {
    var primaryRecommendation: String
    var reason: String
    var tips: [RecommendationTip]
}

struct RecommendationTip: Identifiable, Codable, Equatable {
    let id: UUID
    var icon: String
    var title: String
    var description: String

    init(id: UUID = UUID(), icon: String, title: String, description: String) {
        self.id = id
        self.icon = icon
        self.title = title
        self.description = description
    }
}

struct FullPlanResult: Codable, Equatable {
    var plan1: Plan1Result
    var plan2: Plan2Result?
    var plan3: Plan3Result? 
    var feasibility: FeasibilityResult
    var recommendations: PlanRecommendations
    var comparisonScore: PlanComparisonScore?
    var goalCategory: InvestmentGoalCategory
    var financialHealthSummary: FinancialHealthContext

    var mentalityGrowthValue: Double?
    var mentalityGrowthLabel: String?
}

enum InvestmentGoalCategory: String, Codable, CaseIterable {
    case retirement = "Retirement"
    case education = "Education"
    case homePurchase = "Home Purchase"
    case vehiclePurchase = "Vehicle Purchase"
    case travel = "Travel"
    case wedding = "Wedding"
    case wealthCreation = "Wealth Creation"
    case business = "Business Fund"
    case emergency = "Emergency Fund"
    case other = "Other"

    static func from(purpose: String) -> InvestmentGoalCategory {
        let p = purpose.lowercased()
        if p.contains("retire") { return .retirement }
        if p.contains("edu") { return .education }
        if p.contains("home") || p.contains("house") || p.contains("property") { return .homePurchase }
        if p.contains("car") || p.contains("vehicle") || p.contains("bike") { return .vehiclePurchase }
        if p.contains("trip") || p.contains("travel") || p.contains("holiday") { return .travel }
        if p.contains("wed") || p.contains("marry") { return .wedding }
        if p.contains("business") || p.contains("startup") { return .business }
        if p.contains("emerg") { return .emergency }
        if p.contains("wealth") || p.contains("invest") || p.contains("freedom") { return .wealthCreation }
        return .other
    }
}

struct PlanComparisonScore: Codable, Equatable {
    var plan1Score: Double     
    var plan2Score: Double     
    var plan3Score: Double?    
    var winner: String         
    var confidence: String     
    var dimensions: [ScoreDimension]
    var detailedReasoning: String
    var keyValidations: [ValidationPoint]
}

struct ScoreDimension: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    let axis: String           
    let plan1Value: String
    let plan2Value: String
    let plan3Value: String?
    let plan1Points: Double    
    let plan2Points: Double    
    let plan3Points: Double?   
    let weight: Double         
    let winner: String         
}

struct ValidationPoint: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var icon: String
    var title: String
    var detail: String
    var severity: ValidationSeverity
}

enum ValidationSeverity: String, Codable {
    case positive, warning, critical
}

struct FinancialHealthContext: Codable, Equatable {
    var netWorth: Double
    var monthlyIncome: Double         
    var monthlyExpenses: Double
    var existingEMIBurden: Double     
    var emergencyFundCoverage: Double 
    var investmentScore: Int
    var debtToIncomeRatio: Double
    var investableMonthly: Double     
    var healthGrade: String           
    var healthSummary: String
}

enum InvestmentMentality: String, Codable, CaseIterable {
    case mutualFunds = "Mutual Funds"
    case stocks = "Stocks"
    case realEstate = "Real Estate"
    case crypto = "Crypto / High Risk"
    case debt = "Fixed Income / Debt"

    var avgGrowthRate: Double {
        switch self {
        case .mutualFunds: return 12.0
        case .stocks: return 15.6
        case .realEstate: return 8.0
        case .crypto: return 24.0
        case .debt: return 7.2
        }
    }

    var icon: String {
        switch self {
        case .mutualFunds: return "chart.pie.fill"
        case .stocks: return "chart.line.uptrend.xyaxis"
        case .realEstate: return "house.fill"
        case .crypto: return "bitcoinsign.circle.fill"
        case .debt: return "shield.fill"
        }
    }
}
