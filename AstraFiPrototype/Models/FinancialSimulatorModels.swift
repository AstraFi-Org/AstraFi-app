import Foundation
import SwiftUI

// MARK: - =====================================================================
// MARK: 1. SHARED SIMULATION INPUT LAYER & ENUMS
// MARK: - =====================================================================

/// Baseline personal & financial profile data that can seed simulations
struct SharedSimulationProfile: Codable, Equatable {
    var currentAge: Int
    var plannedRetirementAge: Int
    var lifeExpectancy: Int
    var monthlyIncome: Double
    var monthlyEssentialExpenses: Double
    var monthlyDiscretionaryExpenses: Double
    var currentSavings: Double
    var existingInvestments: Double
    var totalMonthlyEMI: Double
    var monthlySurplus: Double
    var expectedIncomeGrowthRate: Double
    var expectedInflationRate: Double

    init(
        currentAge: Int = 30,
        plannedRetirementAge: Int = 60,
        lifeExpectancy: Int = 85,
        monthlyIncome: Double = 120_000,
        monthlyEssentialExpenses: Double = 50_000,
        monthlyDiscretionaryExpenses: Double = 20_000,
        currentSavings: Double = 300_000,
        existingInvestments: Double = 1_200_000,
        totalMonthlyEMI: Double = 15_000,
        monthlySurplus: Double = 35_000,
        expectedIncomeGrowthRate: Double = 0.08,
        expectedInflationRate: Double = 0.06
    ) {
        self.currentAge = currentAge
        self.plannedRetirementAge = plannedRetirementAge
        self.lifeExpectancy = lifeExpectancy
        self.monthlyIncome = monthlyIncome
        self.monthlyEssentialExpenses = monthlyEssentialExpenses
        self.monthlyDiscretionaryExpenses = monthlyDiscretionaryExpenses
        self.currentSavings = currentSavings
        self.existingInvestments = existingInvestments
        self.totalMonthlyEMI = totalMonthlyEMI
        self.monthlySurplus = monthlySurplus
        self.expectedIncomeGrowthRate = expectedIncomeGrowthRate
        self.expectedInflationRate = expectedInflationRate
    }

    /// Factory to seed from AstraUserProfile
    static func from(profile: AstraUserProfile?) -> SharedSimulationProfile {
        guard let p = profile else { return SharedSimulationProfile() }
        let age = p.basicDetails.age > 0 ? p.basicDetails.age : 30
        let inc = p.basicDetails.monthlyIncome > 0 ? p.basicDetails.monthlyIncome : 120_000
        let exp = p.basicDetails.monthlyExpenses > 0 ? p.basicDetails.monthlyExpenses : 60_000
        let essential = exp * 0.70
        let disc = exp * 0.30
        let savings = p.basicDetails.emergencyFundAmount > 0 ? p.basicDetails.emergencyFundAmount : 300_000
        let totalInvestments = p.investments.reduce(0.0) { $0 + $1.investmentAmount }
        let emi = p.loans.reduce(0.0) { $0 + ($1.emiAmount ?? 0.0) }
        let surplus = max(0, inc - exp - emi)

        return SharedSimulationProfile(
            currentAge: age,
            plannedRetirementAge: 60,
            lifeExpectancy: 85,
            monthlyIncome: inc,
            monthlyEssentialExpenses: essential,
            monthlyDiscretionaryExpenses: disc,
            currentSavings: savings,
            existingInvestments: totalInvestments > 0 ? totalInvestments : 500_000,
            totalMonthlyEMI: emi,
            monthlySurplus: surplus,
            expectedIncomeGrowthRate: 0.08,
            expectedInflationRate: 0.06
        )
    }
}

// MARK: - =====================================================================
// MARK: 2. FIXED-INCOME LADDER MODELS
// MARK: - =====================================================================

enum FixedIncomeInstrumentType: String, Codable, CaseIterable, Identifiable {
    case bankFD = "Bank Fixed Deposit"
    case treasuryBill = "Treasury Bill (T-Bill)"
    case governmentSecurity = "Government Security (G-Sec)"
    case corporateBond = "Corporate Bond"
    case sgb = "Sovereign Gold Bond"
    case customBond = "Other Fixed-Income"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .bankFD: return "Bank FD"
        case .treasuryBill: return "T-Bill"
        case .governmentSecurity: return "G-Sec"
        case .corporateBond: return "Corp Bond"
        case .sgb: return "SGB"
        case .customBond: return "Bond"
        }
    }

    var defaultRatePct: Double {
        switch self {
        case .bankFD: return 7.25
        case .treasuryBill: return 6.85
        case .governmentSecurity: return 7.15
        case .corporateBond: return 8.50
        case .sgb: return 2.50
        case .customBond: return 7.50
        }
    }

    var defaultFrequency: FixedIncomePayoutFrequency {
        switch self {
        case .bankFD: return .quarterlyCompounding
        case .treasuryBill: return .atMaturityDiscount
        case .governmentSecurity: return .semiAnnualCoupon
        case .corporateBond: return .annualCoupon
        case .sgb: return .semiAnnualCoupon
        case .customBond: return .annualCoupon
        }
    }

    var creditRiskDescription: String {
        switch self {
        case .bankFD: return "DICGC cover up to ₹5L per bank; credit risk is minimal for systemically important banks."
        case .treasuryBill: return "Sovereign backing, zero credit risk, short-term money-market instrument."
        case .governmentSecurity: return "Sovereign backing, zero credit risk. Subject to interest-rate risk if liquidated early."
        case .corporateBond: return "Credit risk tied to issuer credit rating (AAA down to BBB/default risk)."
        case .sgb: return "Sovereign guarantee on redemption value and 2.5% semi-annual interest."
        case .customBond: return "Subject to individual issuer terms and credit standing."
        }
    }

    var isSovereign: Bool {
        switch self {
        case .treasuryBill, .governmentSecurity, .sgb: return true
        default: return false
        }
    }
}

enum FixedIncomePayoutFrequency: String, Codable, CaseIterable, Identifiable {
    case monthly = "Monthly Payout"
    case quarterly = "Quarterly Payout"
    case semiAnnualCoupon = "Semi-Annual Coupon"
    case annualCoupon = "Annual Coupon"
    case quarterlyCompounding = "Quarterly Cumulative (At Maturity)"
    case atMaturityDiscount = "Discount to Face Value (T-Bill)"

    var id: String { rawValue }

    var isCumulative: Bool {
        self == .quarterlyCompounding || self == .atMaturityDiscount
    }
}

enum FixedIncomeCompounding: String, Codable, CaseIterable, Identifiable {
    case quarterly = "Quarterly Compounding"
    case semiAnnual = "Semi-Annual Compounding"
    case annual = "Annual Compounding"
    case noneSimple = "Simple / None"

    var id: String { rawValue }
}

enum FixedIncomeReinvestmentAction: String, Codable, CaseIterable, Identifiable {
    case reinvestLadder = "Reinvest into New Ladder Leg"
    case cashBalance = "Transfer to Cash / Savings"
    case allocateToGoal = "Allocate to Goal / Expense"

    var id: String { rawValue }
}

struct FixedIncomeEntry: Codable, Identifiable, Equatable {
    var id: UUID
    var instrumentName: String
    var instrumentType: FixedIncomeInstrumentType
    var allocatedAmount: Double
    var startYearOffset: Int
    var tenureYears: Int
    var annualInterestRatePct: Double
    var payoutFrequency: FixedIncomePayoutFrequency
    var compounding: FixedIncomeCompounding
    var taxRatePct: Double
    var feePct: Double
    var reinvestmentAction: FixedIncomeReinvestmentAction
    var reinvestmentRatePct: Double
    var plannedWithdrawalAtMaturity: Double

    init(
        id: UUID = UUID(),
        instrumentName: String = "1-Year Bank FD",
        instrumentType: FixedIncomeInstrumentType = .bankFD,
        allocatedAmount: Double = 200_000,
        startYearOffset: Int = 0,
        tenureYears: Int = 1,
        annualInterestRatePct: Double = 7.25,
        payoutFrequency: FixedIncomePayoutFrequency = .quarterlyCompounding,
        compounding: FixedIncomeCompounding = .quarterly,
        taxRatePct: Double = 20.0,
        feePct: Double = 0.0,
        reinvestmentAction: FixedIncomeReinvestmentAction = .reinvestLadder,
        reinvestmentRatePct: Double = 7.0,
        plannedWithdrawalAtMaturity: Double = 0.0
    ) {
        self.id = id
        self.instrumentName = instrumentName
        self.instrumentType = instrumentType
        self.allocatedAmount = allocatedAmount
        self.startYearOffset = startYearOffset
        self.tenureYears = max(1, tenureYears)
        self.annualInterestRatePct = annualInterestRatePct
        self.payoutFrequency = payoutFrequency
        self.compounding = compounding
        self.taxRatePct = taxRatePct
        self.feePct = feePct
        self.reinvestmentAction = reinvestmentAction
        self.reinvestmentRatePct = reinvestmentRatePct
        self.plannedWithdrawalAtMaturity = plannedWithdrawalAtMaturity
    }

    var maturityYearOffset: Int {
        startYearOffset + tenureYears
    }
}

struct FixedIncomeLadderInput: Codable, Equatable {
    var totalCapitalAvailable: Double
    var desiredLiquidityReserve: Double
    var ladderEntries: [FixedIncomeEntry]
    var inflationAssumptionPct: Double
    var scenarioKind: PlanningScenarioKind

    init(
        totalCapitalAvailable: Double = 1_000_000,
        desiredLiquidityReserve: Double = 100_000,
        ladderEntries: [FixedIncomeEntry]? = nil,
        inflationAssumptionPct: Double = 6.0,
        scenarioKind: PlanningScenarioKind = .base
    ) {
        self.totalCapitalAvailable = totalCapitalAvailable
        self.desiredLiquidityReserve = desiredLiquidityReserve
        self.ladderEntries = ladderEntries ?? Self.defaultLadder()
        self.inflationAssumptionPct = inflationAssumptionPct
        self.scenarioKind = scenarioKind
    }

    static func defaultLadder() -> [FixedIncomeEntry] {
        [
            FixedIncomeEntry(
                instrumentName: "Tranche 1: 1-Yr FD",
                instrumentType: .bankFD,
                allocatedAmount: 200_000,
                startYearOffset: 0,
                tenureYears: 1,
                annualInterestRatePct: 7.25,
                payoutFrequency: .quarterlyCompounding,
                compounding: .quarterly,
                reinvestmentAction: .reinvestLadder,
                reinvestmentRatePct: 7.0
            ),
            FixedIncomeEntry(
                instrumentName: "Tranche 2: 2-Yr T-Bill / FD",
                instrumentType: .bankFD,
                allocatedAmount: 200_000,
                startYearOffset: 0,
                tenureYears: 2,
                annualInterestRatePct: 7.35,
                payoutFrequency: .quarterlyCompounding,
                compounding: .quarterly,
                reinvestmentAction: .reinvestLadder,
                reinvestmentRatePct: 7.0
            ),
            FixedIncomeEntry(
                instrumentName: "Tranche 3: 3-Yr G-Sec",
                instrumentType: .governmentSecurity,
                allocatedAmount: 250_000,
                startYearOffset: 0,
                tenureYears: 3,
                annualInterestRatePct: 7.15,
                payoutFrequency: .semiAnnualCoupon,
                compounding: .semiAnnual,
                reinvestmentAction: .reinvestLadder,
                reinvestmentRatePct: 7.0
            ),
            FixedIncomeEntry(
                instrumentName: "Tranche 4: 4-Yr Corp Bond",
                instrumentType: .corporateBond,
                allocatedAmount: 150_000,
                startYearOffset: 0,
                tenureYears: 4,
                annualInterestRatePct: 8.40,
                payoutFrequency: .annualCoupon,
                compounding: .annual,
                reinvestmentAction: .cashBalance,
                reinvestmentRatePct: 7.0
            ),
            FixedIncomeEntry(
                instrumentName: "Tranche 5: 5-Yr G-Sec",
                instrumentType: .governmentSecurity,
                allocatedAmount: 100_000,
                startYearOffset: 0,
                tenureYears: 5,
                annualInterestRatePct: 7.20,
                payoutFrequency: .semiAnnualCoupon,
                compounding: .semiAnnual,
                reinvestmentAction: .cashBalance,
                reinvestmentRatePct: 7.0
            )
        ]
    }
}

struct LadderCashFlowEvent: Codable, Identifiable, Equatable {
    var id: UUID
    var yearOffset: Int
    var instrumentName: String
    var instrumentType: FixedIncomeInstrumentType
    var eventDescription: String
    var grossCashInflow: Double
    var taxAndFeesDeducted: Double
    var netCashInflow: Double
    var isMaturityPrincipal: Bool

    init(
        id: UUID = UUID(),
        yearOffset: Int,
        instrumentName: String,
        instrumentType: FixedIncomeInstrumentType,
        eventDescription: String,
        grossCashInflow: Double,
        taxAndFeesDeducted: Double,
        netCashInflow: Double,
        isMaturityPrincipal: Bool
    ) {
        self.id = id
        self.yearOffset = yearOffset
        self.instrumentName = instrumentName
        self.instrumentType = instrumentType
        self.eventDescription = eventDescription
        self.grossCashInflow = grossCashInflow
        self.taxAndFeesDeducted = taxAndFeesDeducted
        self.netCashInflow = netCashInflow
        self.isMaturityPrincipal = isMaturityPrincipal
    }
}

struct LadderYearlySummary: Codable, Identifiable, Equatable {
    var yearOffset: Int
    var totalInterestReceived: Double
    var totalMaturityProceeds: Double
    var totalPrincipalReturned: Double
    var totalReinvested: Double
    var totalTaxesAndFees: Double
    var plannedWithdrawalsPaid: Double
    var availableCashBalance: Double
    var endingLadderInvestedBalance: Double

    var id: Int { yearOffset }
}

struct LadderStressScenario: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var description: String
    var reinvestmentRateDropPct: Double
    var expenseInflationIncreasePct: Double
    var prematureBondSaleHaircutPct: Double
    var corporateDefaultRecoveryPct: Double?

    init(
        id: String,
        title: String,
        description: String,
        reinvestmentRateDropPct: Double = 0.0,
        expenseInflationIncreasePct: Double = 0.0,
        prematureBondSaleHaircutPct: Double = 0.0,
        corporateDefaultRecoveryPct: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.reinvestmentRateDropPct = reinvestmentRateDropPct
        self.expenseInflationIncreasePct = expenseInflationIncreasePct
        self.prematureBondSaleHaircutPct = prematureBondSaleHaircutPct
        self.corporateDefaultRecoveryPct = corporateDefaultRecoveryPct
    }

    static let standardScenarios: [LadderStressScenario] = [
        LadderStressScenario(
            id: "baseline",
            title: "Baseline Contractual",
            description: "No rate shocks or stress events. All instruments fulfill contractual terms."
        ),
        LadderStressScenario(
            id: "rate_cut_2pct",
            title: "Reinvestment Rate Slump (-2.0%)",
            description: "Interest rate cycle shifts lower. Maturing tranches reinvest at 200 bps lower yields.",
            reinvestmentRateDropPct: 2.0
        ),
        LadderStressScenario(
            id: "rate_cut_3pct_inflation",
            title: "Stagflation Stress (-3% Yield, +3% Inflation)",
            description: "Yields fall by 3% while living expenses rise 3% faster, straining post-maturity liquidity.",
            reinvestmentRateDropPct: 3.0,
            expenseInflationIncreasePct: 3.0
        ),
        LadderStressScenario(
            id: "liquidity_crunch_sale",
            title: "Premature Bond Liquidation (-8% Haircut)",
            description: "Emergency requires selling market-linked bonds before maturity at discounted secondary rates.",
            prematureBondSaleHaircutPct: 8.0
        ),
        LadderStressScenario(
            id: "corp_default",
            title: "Corporate Credit Stress (60% Recovery)",
            description: "Non-sovereign corporate bonds suffer credit distress with 40% haircut on maturity principal.",
            corporateDefaultRecoveryPct: 60.0
        )
    ]
}

struct FixedIncomeLadderResult: Codable, Equatable {
    var totalCapitalAllocated: Double
    var unallocatedCapital: Double
    var totalCumulativeInterestGross: Double
    var totalCumulativeInterestNet: Double
    var totalMaturityProceedsGross: Double
    var totalTaxesAndFees: Double
    var totalReinvestedAmount: Double
    var totalWithdrawalsPaid: Double
    var endingPortfolioValue: Double
    var endingAvailableCash: Double
    var timelineEvents: [LadderCashFlowEvent]
    var yearlySummaries: [LadderYearlySummary]
    var allocationByInstrument: [String: Double]
    var allocationByMaturityYear: [Int: Double]
    var liquidityGaps: [String]
    var concentrationWarnings: [String]
    var feasibility: PlanFeasibility
    var feasibilityExplanation: String
    var stressTestResults: [String: Double] // scenarioId -> endingCash

    init(
        totalCapitalAllocated: Double,
        unallocatedCapital: Double,
        totalCumulativeInterestGross: Double,
        totalCumulativeInterestNet: Double,
        totalMaturityProceedsGross: Double,
        totalTaxesAndFees: Double,
        totalReinvestedAmount: Double,
        totalWithdrawalsPaid: Double,
        endingPortfolioValue: Double,
        endingAvailableCash: Double,
        timelineEvents: [LadderCashFlowEvent],
        yearlySummaries: [LadderYearlySummary],
        allocationByInstrument: [String: Double],
        allocationByMaturityYear: [Int: Double],
        liquidityGaps: [String],
        concentrationWarnings: [String],
        feasibility: PlanFeasibility,
        feasibilityExplanation: String,
        stressTestResults: [String: Double] = [:]
    ) {
        self.totalCapitalAllocated = totalCapitalAllocated
        self.unallocatedCapital = unallocatedCapital
        self.totalCumulativeInterestGross = totalCumulativeInterestGross
        self.totalCumulativeInterestNet = totalCumulativeInterestNet
        self.totalMaturityProceedsGross = totalMaturityProceedsGross
        self.totalTaxesAndFees = totalTaxesAndFees
        self.totalReinvestedAmount = totalReinvestedAmount
        self.totalWithdrawalsPaid = totalWithdrawalsPaid
        self.endingPortfolioValue = endingPortfolioValue
        self.endingAvailableCash = endingAvailableCash
        self.timelineEvents = timelineEvents
        self.yearlySummaries = yearlySummaries
        self.allocationByInstrument = allocationByInstrument
        self.allocationByMaturityYear = allocationByMaturityYear
        self.liquidityGaps = liquidityGaps
        self.concentrationWarnings = concentrationWarnings
        self.feasibility = feasibility
        self.feasibilityExplanation = feasibilityExplanation
        self.stressTestResults = stressTestResults
    }

    static func empty() -> FixedIncomeLadderResult {
        FixedIncomeLadderResult(
            totalCapitalAllocated: 0,
            unallocatedCapital: 0,
            totalCumulativeInterestGross: 0,
            totalCumulativeInterestNet: 0,
            totalMaturityProceedsGross: 0,
            totalTaxesAndFees: 0,
            totalReinvestedAmount: 0,
            totalWithdrawalsPaid: 0,
            endingPortfolioValue: 0,
            endingAvailableCash: 0,
            timelineEvents: [],
            yearlySummaries: [],
            allocationByInstrument: [:],
            allocationByMaturityYear: [:],
            liquidityGaps: [],
            concentrationWarnings: [],
            feasibility: .healthy,
            feasibilityExplanation: "No ladder entries configured."
        )
    }
}

// MARK: - =====================================================================
// MARK: 3. REIT & LISTED ASSETS MODELS
// MARK: - =====================================================================

struct REITSimulatorInput: Codable, Equatable {
    var assetName: String
    var initialLumpSumInvestment: Double
    var recurringMonthlyContribution: Double
    var investmentHorizonYears: Int
    var purchasePricePerUnit: Double
    var distributionYieldPct: Double
    var expectedAnnualDistributionGrowthPct: Double
    var expectedAnnualPriceAppreciationPct: Double
    var reinvestDistributions: Bool
    var transactionCostPct: Double
    var distributionTaxPct: Double
    var capitalGainsTaxPct: Double
    var scenarioKind: PlanningScenarioKind

    init(
        assetName: String = "Embassy / Brookfield / Nexus REIT Basket",
        initialLumpSumInvestment: Double = 500_000,
        recurringMonthlyContribution: Double = 15_000,
        investmentHorizonYears: Int = 10,
        purchasePricePerUnit: Double = 350.0,
        distributionYieldPct: Double = 6.8,
        expectedAnnualDistributionGrowthPct: Double = 4.0,
        expectedAnnualPriceAppreciationPct: Double = 5.0,
        reinvestDistributions: Bool = true,
        transactionCostPct: Double = 0.5,
        distributionTaxPct: Double = 10.0,
        capitalGainsTaxPct: Double = 12.5,
        scenarioKind: PlanningScenarioKind = .base
    ) {
        self.assetName = assetName
        self.initialLumpSumInvestment = initialLumpSumInvestment
        self.recurringMonthlyContribution = recurringMonthlyContribution
        self.investmentHorizonYears = max(0, investmentHorizonYears)
        self.purchasePricePerUnit = max(1.0, purchasePricePerUnit)
        self.distributionYieldPct = distributionYieldPct
        self.expectedAnnualDistributionGrowthPct = expectedAnnualDistributionGrowthPct
        self.expectedAnnualPriceAppreciationPct = expectedAnnualPriceAppreciationPct
        self.reinvestDistributions = reinvestDistributions
        self.transactionCostPct = transactionCostPct
        self.distributionTaxPct = distributionTaxPct
        self.capitalGainsTaxPct = capitalGainsTaxPct
        self.scenarioKind = scenarioKind
    }
}

struct REITYearlySnapshot: Codable, Identifiable, Equatable {
    var year: Int
    var beginningUnits: Double
    var endingUnits: Double
    var unitPrice: Double
    var distributionPerUnit: Double
    var cumulativeContributions: Double
    var annualContributions: Double
    var grossDistributionsReceived: Double
    var netDistributionsReceived: Double
    var unitsBoughtFromReinvestment: Double
    var endingPortfolioMarketValue: Double
    var cumulativeCashReceived: Double
    var totalEconomicValue: Double
    var unrealizedCapitalGain: Double
    var annualTotalReturnPct: Double

    var id: Int { year }
}

struct REITStressScenario: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var description: String
    var distributionCutPct: Double
    var unitPriceDropPct: Double
    var zeroDistributionGrowth: Bool

    init(
        id: String,
        title: String,
        description: String,
        distributionCutPct: Double = 0.0,
        unitPriceDropPct: Double = 0.0,
        zeroDistributionGrowth: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.distributionCutPct = distributionCutPct
        self.unitPriceDropPct = unitPriceDropPct
        self.zeroDistributionGrowth = zeroDistributionGrowth
    }

    static let standardScenarios: [REITStressScenario] = [
        REITStressScenario(
            id: "base",
            title: "Baseline Assumptions",
            description: "Standard model with user-provided yields and historical escalation."
        ),
        REITStressScenario(
            id: "dist_cut_20",
            title: "Commercial Vacancy Shock (-20% Distribution)",
            description: "Occupancy dips reduce tenant rental collections, cutting payout by 20%.",
            distributionCutPct: 20.0
        ),
        REITStressScenario(
            id: "rate_hike_price_drop",
            title: "Yield Expansion Shock (-15% Unit Price)",
            description: "Rising sovereign rates push cap rates up, triggering a 15% unit price decline.",
            unitPriceDropPct: 15.0
        ),
        REITStressScenario(
            id: "severe_stagflation",
            title: "Severe Commercial Downturn (-30% Payout, -25% Price)",
            description: "Simultaneous rent renegotiations and capital depreciation without growth.",
            distributionCutPct: 30.0,
            unitPriceDropPct: 25.0,
            zeroDistributionGrowth: true
        )
    ]
}

struct REITSimulatorResult: Codable, Equatable {
    var totalCapitalInvested: Double
    var totalUnitsAccumulated: Double
    var finalUnitPrice: Double
    var finalPortfolioMarketValue: Double
    var cumulativeGrossDistributions: Double
    var cumulativeNetDistributions: Double
    var cumulativeReinvestedCapital: Double
    var totalTaxesAndCosts: Double
    var totalNetEconomicValue: Double
    var netAbsoluteReturnPct: Double
    var annualizedCAGR: Double
    var finalAnnualRunrateDistribution: Double
    var yearlySnapshots: [REITYearlySnapshot]
    var stressTestComparisons: [String: Double] // scenarioId -> endingEconomicValue
    var feasibility: PlanFeasibility
    var summaryNotes: [String]

    init(
        totalCapitalInvested: Double,
        totalUnitsAccumulated: Double,
        finalUnitPrice: Double,
        finalPortfolioMarketValue: Double,
        cumulativeGrossDistributions: Double,
        cumulativeNetDistributions: Double,
        cumulativeReinvestedCapital: Double,
        totalTaxesAndCosts: Double,
        totalNetEconomicValue: Double,
        netAbsoluteReturnPct: Double,
        annualizedCAGR: Double,
        finalAnnualRunrateDistribution: Double,
        yearlySnapshots: [REITYearlySnapshot],
        stressTestComparisons: [String: Double] = [:],
        feasibility: PlanFeasibility,
        summaryNotes: [String] = []
    ) {
        self.totalCapitalInvested = totalCapitalInvested
        self.totalUnitsAccumulated = totalUnitsAccumulated
        self.finalUnitPrice = finalUnitPrice
        self.finalPortfolioMarketValue = finalPortfolioMarketValue
        self.cumulativeGrossDistributions = cumulativeGrossDistributions
        self.cumulativeNetDistributions = cumulativeNetDistributions
        self.cumulativeReinvestedCapital = cumulativeReinvestedCapital
        self.totalTaxesAndCosts = totalTaxesAndCosts
        self.totalNetEconomicValue = totalNetEconomicValue
        self.netAbsoluteReturnPct = netAbsoluteReturnPct
        self.annualizedCAGR = annualizedCAGR
        self.finalAnnualRunrateDistribution = finalAnnualRunrateDistribution
        self.yearlySnapshots = yearlySnapshots
        self.stressTestComparisons = stressTestComparisons
        self.feasibility = feasibility
        self.summaryNotes = summaryNotes
    }

    static func empty() -> REITSimulatorResult {
        REITSimulatorResult(
            totalCapitalInvested: 0,
            totalUnitsAccumulated: 0,
            finalUnitPrice: 0,
            finalPortfolioMarketValue: 0,
            cumulativeGrossDistributions: 0,
            cumulativeNetDistributions: 0,
            cumulativeReinvestedCapital: 0,
            totalTaxesAndCosts: 0,
            totalNetEconomicValue: 0,
            netAbsoluteReturnPct: 0,
            annualizedCAGR: 0,
            finalAnnualRunrateDistribution: 0,
            yearlySnapshots: [],
            stressTestComparisons: [:],
            feasibility: .healthy,
            summaryNotes: []
        )
    }
}

// MARK: - =====================================================================
// MARK: 4. RETIREMENT SWP & WITHDRAWAL MODELS
// MARK: - =====================================================================

enum RetirementSWPWithdrawalMode: String, Codable, CaseIterable, Identifiable {
    case inflationAdjusted = "Inflation-Adjusted Monthly Drawdown"
    case fixedNominal = "Fixed Flat Monthly Amount"
    case percentageOfPortfolio = "Variable Portfolio Percentage (e.g., 4% Rule)"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .inflationAdjusted:
            return "Monthly withdrawals increase every year to match lifestyle and healthcare inflation."
        case .fixedNominal:
            return "Withdrawals stay constant in nominal rupees; real purchasing power decays over time."
        case .percentageOfPortfolio:
            return "Withdraw a fixed percentage of current portfolio balance each year, protecting against total depletion."
        }
    }
}

struct RetirementSWPInput: Codable, Equatable {
    var currentAge: Int
    var retirementAge: Int
    var lifeExpectancyAge: Int
    var currentRetirementCorpus: Double
    var monthlySIPPreRetirement: Double
    var annualSIPStepUpRatePct: Double
    var preRetirementReturnPct: Double
    var postRetirementReturnPct: Double
    var monthlyLifestyleExpenseToday: Double
    var monthlyHealthcareExpenseToday: Double
    var lifestyleInflationPct: Double
    var healthcareInflationPct: Double
    var withdrawalMode: RetirementSWPWithdrawalMode
    var fixedWithdrawalRatePct: Double // e.g. 4.0%
    var customInitialMonthlyWithdrawal: Double?
    var monthlyPensionOrGuaranteedIncome: Double
    var managementFeePct: Double
    var postRetirementTaxPct: Double
    var scenarioKind: PlanningScenarioKind

    init(
        currentAge: Int = 32,
        retirementAge: Int = 60,
        lifeExpectancyAge: Int = 85,
        currentRetirementCorpus: Double = 1_500_000,
        monthlySIPPreRetirement: Double = 30_000,
        annualSIPStepUpRatePct: Double = 8.0,
        preRetirementReturnPct: Double = 11.0,
        postRetirementReturnPct: Double = 7.0,
        monthlyLifestyleExpenseToday: Double = 60_000,
        monthlyHealthcareExpenseToday: Double = 10_000,
        lifestyleInflationPct: Double = 6.0,
        healthcareInflationPct: Double = 8.0,
        withdrawalMode: RetirementSWPWithdrawalMode = .inflationAdjusted,
        fixedWithdrawalRatePct: Double = 4.0,
        customInitialMonthlyWithdrawal: Double? = nil,
        monthlyPensionOrGuaranteedIncome: Double = 15_000,
        managementFeePct: Double = 0.5,
        postRetirementTaxPct: Double = 10.0,
        scenarioKind: PlanningScenarioKind = .base
    ) {
        self.currentAge = currentAge
        self.retirementAge = max(currentAge, retirementAge)
        self.lifeExpectancyAge = max(self.retirementAge + 1, lifeExpectancyAge)
        self.currentRetirementCorpus = currentRetirementCorpus
        self.monthlySIPPreRetirement = monthlySIPPreRetirement
        self.annualSIPStepUpRatePct = annualSIPStepUpRatePct
        self.preRetirementReturnPct = preRetirementReturnPct
        self.postRetirementReturnPct = postRetirementReturnPct
        self.monthlyLifestyleExpenseToday = monthlyLifestyleExpenseToday
        self.monthlyHealthcareExpenseToday = monthlyHealthcareExpenseToday
        self.lifestyleInflationPct = lifestyleInflationPct
        self.healthcareInflationPct = healthcareInflationPct
        self.withdrawalMode = withdrawalMode
        self.fixedWithdrawalRatePct = fixedWithdrawalRatePct
        self.customInitialMonthlyWithdrawal = customInitialMonthlyWithdrawal
        self.monthlyPensionOrGuaranteedIncome = monthlyPensionOrGuaranteedIncome
        self.managementFeePct = managementFeePct
        self.postRetirementTaxPct = postRetirementTaxPct
        self.scenarioKind = scenarioKind
    }

    var yearsToRetirement: Int {
        max(0, retirementAge - currentAge)
    }

    var yearsInRetirement: Int {
        max(0, lifeExpectancyAge - retirementAge)
    }
}

struct RetirementAccumulationYear: Codable, Identifiable, Equatable {
    var age: Int
    var yearOffset: Int
    var beginningBalance: Double
    var monthlySIPAmount: Double
    var annualContributions: Double
    var investmentReturns: Double
    var endingBalance: Double

    var id: Int { yearOffset }
}

struct RetirementWithdrawalYear: Codable, Identifiable, Equatable {
    var age: Int
    var yearOffsetInRetirement: Int
    var beginningCorpus: Double
    var grossWithdrawals: Double
    var pensionIncome: Double
    var netDrawdownFromCorpus: Double
    var investmentReturns: Double
    var managementFeesAndTaxes: Double
    var endingCorpus: Double
    var monthlyDrawdownAmount: Double
    var realPurchasingPowerValue: Double
    var isDepleted: Bool

    var id: Int { age }
}

struct RetirementStressScenario: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var description: String
    var returnReductionPct: Double
    var inflationIncreasePct: Double
    var retirementAgeShiftYears: Int
    var longevityShiftYears: Int
    var earlySequenceOfReturnsShockPct: Double

    init(
        id: String,
        title: String,
        description: String,
        returnReductionPct: Double = 0.0,
        inflationIncreasePct: Double = 0.0,
        retirementAgeShiftYears: Int = 0,
        longevityShiftYears: Int = 0,
        earlySequenceOfReturnsShockPct: Double = 0.0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.returnReductionPct = returnReductionPct
        self.inflationIncreasePct = inflationIncreasePct
        self.retirementAgeShiftYears = retirementAgeShiftYears
        self.longevityShiftYears = longevityShiftYears
        self.earlySequenceOfReturnsShockPct = earlySequenceOfReturnsShockPct
    }

    static let standardScenarios: [RetirementStressScenario] = [
        RetirementStressScenario(
            id: "baseline",
            title: "Baseline Plan",
            description: "Expected inflation, healthy returns, normal lifespan."
        ),
        RetirementStressScenario(
            id: "sequence_risk_20",
            title: "Sequence of Returns Crash (-20% in Year 1)",
            description: "Equity markets crash 20% right at retirement start, forcing sales in a trough.",
            earlySequenceOfReturnsShockPct: 20.0
        ),
        RetirementStressScenario(
            id: "high_inflation_2pct",
            title: "Persistent Higher Inflation (+2.0%)",
            description: "Lifestyle and medical inflation stay elevated by 200 bps above base.",
            inflationIncreasePct: 2.0
        ),
        RetirementStressScenario(
            id: "lower_returns_2pct",
            title: "Low Yield Environment (-2.0% Returns)",
            description: "Debt and conservative hybrid funds return 200 bps below base expectations.",
            returnReductionPct: 2.0
        ),
        RetirementStressScenario(
            id: "longevity_5yrs",
            title: "Super Longevity (+5 Years)",
            description: "Healthy lifespan extends from age 85 to age 90, requiring 5 more years of income.",
            longevityShiftYears: 5
        ),
        RetirementStressScenario(
            id: "early_retirement_3yrs",
            title: "Early Forced Retirement (-3 Years)",
            description: "Retirement begins 3 years early, reducing accumulation time and adding 3 draw years.",
            retirementAgeShiftYears: -3
        )
    ]
}

struct RetirementSWPResult: Codable, Equatable {
    var projectedCorpusAtRetirement: Double
    var requiredCorpusAtRetirement: Double
    var corpusShortfallOrSurplus: Double
    var isAdequate: Bool
    var depletionAge: Int?
    var yearsCorpusSustained: Int
    var terminalCorpusAtLifeExpectancy: Double
    var totalLifetimeWithdrawn: Double
    var totalLifetimePensionReceived: Double
    var totalLifetimeTaxesAndFees: Double
    var firstYearMonthlyWithdrawal: Double
    var finalYearMonthlyWithdrawal: Double
    var requiredStartingSIPForFullSolvency: Double
    var accumulationTimeline: [RetirementAccumulationYear]
    var withdrawalTimeline: [RetirementWithdrawalYear]
    var stressTestSurvivalAges: [String: Int?] // scenarioId -> depletionAge (nil if survived)
    var feasibility: PlanFeasibility
    var feasibilitySummary: String
    var actionRecommendations: [String]

    init(
        projectedCorpusAtRetirement: Double,
        requiredCorpusAtRetirement: Double,
        corpusShortfallOrSurplus: Double,
        isAdequate: Bool,
        depletionAge: Int?,
        yearsCorpusSustained: Int,
        terminalCorpusAtLifeExpectancy: Double,
        totalLifetimeWithdrawn: Double,
        totalLifetimePensionReceived: Double,
        totalLifetimeTaxesAndFees: Double,
        firstYearMonthlyWithdrawal: Double,
        finalYearMonthlyWithdrawal: Double,
        requiredStartingSIPForFullSolvency: Double,
        accumulationTimeline: [RetirementAccumulationYear],
        withdrawalTimeline: [RetirementWithdrawalYear],
        stressTestSurvivalAges: [String: Int?] = [:],
        feasibility: PlanFeasibility,
        feasibilitySummary: String,
        actionRecommendations: [String] = []
    ) {
        self.projectedCorpusAtRetirement = projectedCorpusAtRetirement
        self.requiredCorpusAtRetirement = requiredCorpusAtRetirement
        self.corpusShortfallOrSurplus = corpusShortfallOrSurplus
        self.isAdequate = isAdequate
        self.depletionAge = depletionAge
        self.yearsCorpusSustained = yearsCorpusSustained
        self.terminalCorpusAtLifeExpectancy = terminalCorpusAtLifeExpectancy
        self.totalLifetimeWithdrawn = totalLifetimeWithdrawn
        self.totalLifetimePensionReceived = totalLifetimePensionReceived
        self.totalLifetimeTaxesAndFees = totalLifetimeTaxesAndFees
        self.firstYearMonthlyWithdrawal = firstYearMonthlyWithdrawal
        self.finalYearMonthlyWithdrawal = finalYearMonthlyWithdrawal
        self.requiredStartingSIPForFullSolvency = requiredStartingSIPForFullSolvency
        self.accumulationTimeline = accumulationTimeline
        self.withdrawalTimeline = withdrawalTimeline
        self.stressTestSurvivalAges = stressTestSurvivalAges
        self.feasibility = feasibility
        self.feasibilitySummary = feasibilitySummary
        self.actionRecommendations = actionRecommendations
    }

    static func empty() -> RetirementSWPResult {
        RetirementSWPResult(
            projectedCorpusAtRetirement: 0,
            requiredCorpusAtRetirement: 0,
            corpusShortfallOrSurplus: 0,
            isAdequate: false,
            depletionAge: 0,
            yearsCorpusSustained: 0,
            terminalCorpusAtLifeExpectancy: 0,
            totalLifetimeWithdrawn: 0,
            totalLifetimePensionReceived: 0,
            totalLifetimeTaxesAndFees: 0,
            firstYearMonthlyWithdrawal: 0,
            finalYearMonthlyWithdrawal: 0,
            requiredStartingSIPForFullSolvency: 0,
            accumulationTimeline: [],
            withdrawalTimeline: [],
            stressTestSurvivalAges: [:],
            feasibility: .notCurrentlyFeasible,
            feasibilitySummary: "No data available.",
            actionRecommendations: []
        )
    }
}
