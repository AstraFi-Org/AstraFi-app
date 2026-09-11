import Foundation

enum AssessmentParameter: String, CaseIterable, Identifiable, Hashable, Codable {
    case vitals
    case investment
    case liabilities
    case insurance
    case emergencyFund

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vitals:        return "Financial Vitals"
        case .investment:    return "Investment Health"
        case .liabilities:   return "Debt Health"
        case .insurance:     return "Risk Protection"
        case .emergencyFund: return "Emergency Readiness"
        }
    }
}

enum AssessmentParameterStatus: String, Hashable, Codable {
    case fine
    case watch
    case concern
    case critical
}

struct AssessmentConcern: Identifiable, Hashable, Codable {
    var id = UUID()
    let parameter: AssessmentParameter
    let status: AssessmentParameterStatus
    let title: String
    let summary: String
    let recommendation: String
}

struct InvestmentRiskBreakdown: Hashable, Codable {
    let highRiskAmount: Double
    let mediumRiskAmount: Double
    let lowRiskAmount: Double
    let lowRiskLiquidAmount: Double
    let highRiskCount: Int

    var totalAmount: Double { highRiskAmount + mediumRiskAmount + lowRiskAmount }

    var highRiskRatio: Double {
        guard totalAmount > 0 else { return 0 }
        return highRiskAmount / totalAmount
    }

    var lowRiskLiquidRatio: Double {
        guard totalAmount > 0 else { return 0 }
        return lowRiskLiquidAmount / totalAmount
    }
}

struct AssessmentParameterSummary: Identifiable, Hashable, Codable {
    var id = UUID()
    let parameter: AssessmentParameter
    let description: String
    let status: AssessmentParameterStatus
    var scoreOutOf10: Double = 0
    var statusTitle: String = ""
}

struct FinancialAssessmentInsights: Hashable, Codable {
    let monthlyIncome: Double
    let grossMonthlyIncome: Double
    let monthlyExpenses: Double
    let monthlySavings: Double
    let savingsRate: Double
    let emergencyFundAmount: Double
    let emergencyFundTarget: Double
    let emergencyCoverageRatio: Double
    let investmentBreakdown: InvestmentRiskBreakdown
    let investmentCount: Int
    let loanCount: Int
    let insuranceCount: Int
    let debtToIncomeRatio: Double
    let hasFixedIncome: Bool
    let concerns: [AssessmentConcern]
    let hasHighRiskDebt: Bool
    let hasHealthInsurance: Bool
    let hasLifeInsurance: Bool
    let adultDependents: Int

    enum CodingKeys: String, CodingKey {
        case monthlyIncome, grossMonthlyIncome, monthlyExpenses, monthlySavings, savingsRate
        case emergencyFundAmount, emergencyFundTarget, emergencyCoverageRatio
        case investmentBreakdown, investmentCount, loanCount, insuranceCount
        case debtToIncomeRatio, hasFixedIncome, concerns, hasHighRiskDebt
        case hasHealthInsurance, hasLifeInsurance, adultDependents
    }

    init(
        monthlyIncome: Double,
        grossMonthlyIncome: Double,
        monthlyExpenses: Double,
        monthlySavings: Double,
        savingsRate: Double,
        emergencyFundAmount: Double,
        emergencyFundTarget: Double,
        emergencyCoverageRatio: Double,
        investmentBreakdown: InvestmentRiskBreakdown,
        investmentCount: Int,
        loanCount: Int,
        insuranceCount: Int,
        debtToIncomeRatio: Double,
        hasFixedIncome: Bool,
        concerns: [AssessmentConcern],
        hasHighRiskDebt: Bool = false,
        hasHealthInsurance: Bool = false,
        hasLifeInsurance: Bool = false,
        adultDependents: Int = 0
    ) {
        self.monthlyIncome = monthlyIncome
        self.grossMonthlyIncome = grossMonthlyIncome
        self.monthlyExpenses = monthlyExpenses
        self.monthlySavings = monthlySavings
        self.savingsRate = savingsRate
        self.emergencyFundAmount = emergencyFundAmount
        self.emergencyFundTarget = emergencyFundTarget
        self.emergencyCoverageRatio = emergencyCoverageRatio
        self.investmentBreakdown = investmentBreakdown
        self.investmentCount = investmentCount
        self.loanCount = loanCount
        self.insuranceCount = insuranceCount
        self.debtToIncomeRatio = debtToIncomeRatio
        self.hasFixedIncome = hasFixedIncome
        self.concerns = concerns
        self.hasHighRiskDebt = hasHighRiskDebt
        self.hasHealthInsurance = hasHealthInsurance
        self.hasLifeInsurance = hasLifeInsurance
        self.adultDependents = adultDependents
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        monthlyIncome = try container.decode(Double.self, forKey: .monthlyIncome)
        grossMonthlyIncome = try container.decode(Double.self, forKey: .grossMonthlyIncome)
        monthlyExpenses = try container.decode(Double.self, forKey: .monthlyExpenses)
        monthlySavings = try container.decode(Double.self, forKey: .monthlySavings)
        savingsRate = try container.decode(Double.self, forKey: .savingsRate)
        emergencyFundAmount = try container.decode(Double.self, forKey: .emergencyFundAmount)
        emergencyFundTarget = try container.decode(Double.self, forKey: .emergencyFundTarget)
        emergencyCoverageRatio = try container.decode(Double.self, forKey: .emergencyCoverageRatio)
        investmentBreakdown = try container.decode(InvestmentRiskBreakdown.self, forKey: .investmentBreakdown)
        investmentCount = try container.decode(Int.self, forKey: .investmentCount)
        loanCount = try container.decode(Int.self, forKey: .loanCount)
        insuranceCount = try container.decode(Int.self, forKey: .insuranceCount)
        debtToIncomeRatio = try container.decode(Double.self, forKey: .debtToIncomeRatio)
        hasFixedIncome = try container.decode(Bool.self, forKey: .hasFixedIncome)
        concerns = try container.decode([AssessmentConcern].self, forKey: .concerns)
        hasHighRiskDebt = try container.decodeIfPresent(Bool.self, forKey: .hasHighRiskDebt) ?? false
        hasHealthInsurance = try container.decodeIfPresent(Bool.self, forKey: .hasHealthInsurance) ?? false
        hasLifeInsurance = try container.decodeIfPresent(Bool.self, forKey: .hasLifeInsurance) ?? false
        adultDependents = try container.decodeIfPresent(Int.self, forKey: .adultDependents) ?? 0
    }

    private enum Threshold {
        static let savingsRateTarget = 0.30
        static let highRiskConcentration = 0.80
        static let healthyDebtToIncome = 0.30
        static let stressedDebtToIncome = 0.45
        static let emergencyFundMonths = 6.0
        static let lowInvestmentBufferMonths = 6.0
    }

    static func build(profile: AstraUserProfile?, data: CompleteAssessmentData?) -> FinancialAssessmentInsights {
        // Core metrics: prioritize assessment data if provided and non-empty
        
        let grossIncomeRaw: Double
        if let data = data, !data.income.isEmpty {
            grossIncomeRaw = parseNumber(data.income)
        } else {
            grossIncomeRaw = profile?.basicDetails.monthlyIncome ?? 0
        }
        let grossIncome = max(0, grossIncomeRaw)

        let takeHomeIncomeRaw: Double
        if let data = data, !data.income.isEmpty {
            takeHomeIncomeRaw = parseNumber(data.income)
        } else {
            takeHomeIncomeRaw = profile?.basicDetails.monthlyIncomeAfterTax ?? grossIncome
        }
        let takeHomeIncome = max(0, takeHomeIncomeRaw)

        let expensesRaw: Double
        if let data = data, !data.expenditure.isEmpty {
            expensesRaw = parseNumber(data.expenditure)
        } else {
            expensesRaw = profile?.basicDetails.monthlyExpenses ?? 0
        }
        let expenses = max(0, expensesRaw)

        let emergencyFundRaw: Double
        if let data = data, !data.emergencyFundAmount.isEmpty {
            emergencyFundRaw = parseNumber(data.emergencyFundAmount)
        } else {
            emergencyFundRaw = profile?.basicDetails.emergencyFundAmount ?? 0
        }
        let emergencyFund = max(0, emergencyFundRaw)

        let savings = takeHomeIncome - expenses
        let savingsRate = takeHomeIncome > 0 ? savings / takeHomeIncome : 0
        let emiForEmergency = FinancialHealthCalculations.totalMonthlyEMI(profile: profile, data: data)
        let (essential, isEstimate) = FinancialHealthCalculations.essentialExpenses(profile: profile, fallbackExpenses: expenses)
        let includeEMI = FinancialHealthCalculations.shouldAddEMIToEmergencyNeed(profile: profile, essential: essential, isEstimate: isEstimate)
        let emergencyMonthlyNeed = max(1, essential + (includeEMI ? emiForEmergency : 0))
        let emergencyTarget = FinancialHealthWeights.emergencyFundMonths * monthlyNeedSafe(emergencyMonthlyNeed, fallbackIncome: grossIncome)
        let emergencyCoverage = emergencyTarget > 0 ? emergencyFund / emergencyTarget : 0

        // Determine investment source:
        // When data is provided (in-progress assessment or newly completed), data.investmentEntries is the
        // single source of truth for the assessment. Also include broker-synced holdings (Upstox) from profile.
        let sourceSnapshots: [InvestmentSnapshot]
        if let data = data {
            var snapshots = data.investmentEntries.map { InvestmentSnapshot(from: $0) }
            if let profile = profile {
                let upstoxSnapshots = profile.investments
                    .filter { $0.brokerSource == "Upstox" }
                    .map { InvestmentSnapshot(from: $0) }
                snapshots.append(contentsOf: upstoxSnapshots)
            }
            sourceSnapshots = snapshots
        } else {
            sourceSnapshots = profile?.investments.map { InvestmentSnapshot(from: $0) } ?? []
        }

        let investmentCount = sourceSnapshots.count
        let investmentBreakdown = buildInvestmentBreakdown(from: sourceSnapshots)

        // Loans and Insurance: use data if assessment data is provided
        let loanCount: Int
        let highRiskDebt: Bool
        if let data = data {
            loanCount = data.loanEntries.count
            highRiskDebt = data.loanEntries.contains { $0.type == .creditCard || $0.type == .personalLoan }
        } else {
            loanCount = profile?.loans.count ?? 0
            highRiskDebt = profile?.loans.contains { $0.loanType == .creditCard || $0.loanType == .personalLoan } ?? false
        }
        
        let insuranceCount: Int
        let hasHealth: Bool
        let hasLife: Bool
        let adultDeps = profile?.basicDetails.adultDependents ?? Int(data?.numberOfDependents ?? "") ?? 0
        if let data = data {
            insuranceCount = data.insuranceEntries.count
            hasHealth = data.insuranceEntries.contains { $0.currentType == .health }
            hasLife = data.insuranceEntries.contains { [.life, .term, .ulip].contains($0.currentType) }
        } else {
            insuranceCount = profile?.insurances.count ?? 0
            hasHealth = profile?.insurances.contains { $0.insuranceType == .health } ?? false
            hasLife = profile?.insurances.contains { [.life, .termLifeInsurance, .ulip].contains($0.insuranceType) } ?? false
        }

        let debtRatio = FinancialHealthCalculations.computeDebtToIncomeRatio(profile: profile, data: data, grossIncome: grossIncome)
        let fixedIncome = (data != nil) ? (data?.incomeType == .fixed) : (profile?.basicDetails.incomeType == .fixed)

        let concerns = buildConcerns(
            savingsRate: savingsRate,
            savings: savings,
            monthlyIncome: takeHomeIncome,
            grossIncome: grossIncome,
            investmentCount: investmentCount,
            investmentBreakdown: investmentBreakdown,
            emergencyFund: emergencyFund,
            emergencyTarget: emergencyTarget,
            insuranceCount: insuranceCount,
            hasHealth: hasHealth,
            hasLife: hasLife,
            adultDependents: adultDeps,
            loanCount: loanCount,
            debtToIncomeRatio: debtRatio
        )

        return FinancialAssessmentInsights(
            monthlyIncome: takeHomeIncome,
            grossMonthlyIncome: grossIncome,
            monthlyExpenses: expenses,
            monthlySavings: savings,
            savingsRate: savingsRate,
            emergencyFundAmount: emergencyFund,
            emergencyFundTarget: emergencyTarget,
            emergencyCoverageRatio: emergencyCoverage,
            investmentBreakdown: investmentBreakdown,
            investmentCount: investmentCount,
            loanCount: loanCount,
            insuranceCount: insuranceCount,
            debtToIncomeRatio: debtRatio,
            hasFixedIncome: fixedIncome,
            concerns: concerns,
            hasHighRiskDebt: highRiskDebt,
            hasHealthInsurance: hasHealth,
            hasLifeInsurance: hasLife,
            adultDependents: adultDeps
        )
    }

    var activeConcerns: [AssessmentConcern] {
        concerns.filter { $0.status != .fine }
    }

    var savingRatioPercent: Int {
        (savingsRate * 100).rounded().safeInt
    }

    var highRiskInvestmentPercent: Int {
        (investmentBreakdown.highRiskRatio * 100).rounded().safeInt
    }

    func status(for parameter: AssessmentParameter) -> AssessmentParameterStatus {
        if concerns.contains(where: { $0.parameter == parameter && $0.status == .critical }) {
            return .critical
        }
        if concerns.contains(where: { $0.parameter == parameter && $0.status == .concern }) {
            return .concern
        }
        if concerns.contains(where: { $0.parameter == parameter && $0.status == .watch }) {
            return .watch
        }
        return .fine
    }

    private var scoringSnapshot: FinancialHealthSnapshot {
        FinancialHealthCalculations.snapshot(from: self, profile: nil, data: nil)
    }

    var parameterSummaries: [AssessmentParameterSummary] {
        let report = FinancialHealthEngine.evaluate(insights: self)
        return report.parameters.map { result in
            AssessmentParameterSummary(
                parameter: result.parameter,
                description: result.oneLineReason,
                status: result.status,
                scoreOutOf10: result.scoreOutOf10,
                statusTitle: result.statusTitle
            )
        }
    }

    var insuranceSummaryText: String {
        if hasHealthInsurance && hasLifeInsurance {
            return "Health + Term Life active (\(insuranceCount) policies)"
        } else if hasHealthInsurance {
            return "Health cover active · \(insuranceCount) polic\(insuranceCount == 1 ? "y" : "ies")"
        } else if hasLifeInsurance {
            return "Term life active · \(insuranceCount) polic\(insuranceCount == 1 ? "y" : "ies")"
        } else if insuranceCount > 0 {
            return "\(insuranceCount) active polic\(insuranceCount == 1 ? "y" : "ies")"
        } else {
            return "No active insurance policies"
        }
    }

    var financialVitalsScore: Double {
        FinancialHealthScoring.calculateFinancialVitals(scoringSnapshot).score
    }

    var savingDisciplineScore: Double { financialVitalsScore }

    var debtHealthScore: Double {
        FinancialHealthScoring.calculateDebtHealth(scoringSnapshot).score
    }

    var emergencyReadinessScore: Double {
        FinancialHealthScoring.calculateEmergencyReadiness(scoringSnapshot).score
    }

    var investmentHealthScore: Double {
        FinancialHealthScoring.calculateInvestmentHealth(scoringSnapshot).score
    }

    var riskProtectionScore: Double {
        FinancialHealthScoring.calculateRiskProtection(scoringSnapshot).score
    }

    var radarValues: [(String, Double, Double)] {
        [
            ("Financial Vitals",    financialVitalsScore, 0.75),
            ("Debt Health",         debtHealthScore, 0.75),
            ("Emergency Readiness", emergencyReadinessScore, 0.75),
            ("Investment Health",   investmentHealthScore, 0.70),
            ("Risk Protection",     riskProtectionScore, 0.70),
        ]
    }

    var overallScore: Double {
        let scores = FinancialHealthScoring.scores(for: scoringSnapshot)
        return scores.overall
    }

    var statusTitle: String {
        Self.statusTitle(for: overallScore.safeInt)
    }

    static func statusTitle(for score: Int) -> String {
        FinancialHealthStatusBand.overallTitle(for: score)
    }

    var expenseRatio: Double {
        monthlyIncome > 0 ? monthlyExpenses / monthlyIncome : 0
    }

    var monthlySurplus: Double { monthlyIncome - monthlyExpenses }

    var emergencyCoverageMonths: Double {
        emergencyCoverageRatio * FinancialHealthWeights.emergencyFundMonths
    }

    var emergencyStatusMessage: String {
        if emergencyFundAmount <= 0 {
            return "No emergency fund found. Target at least \(emergencyFundTarget.toCurrency(compact: true)) (about 6 months of essential expenses)."
        }
        if emergencyFundAmount < emergencyFundTarget {
            let shortBy = emergencyFundTarget - emergencyFundAmount
            return "Emergency fund is partial; increase by \(shortBy.toCurrency(compact: true)) to reach about 6 months of essential expenses."
        }
        if investmentBreakdown.lowRiskLiquidAmount <= 0 {
            return "Emergency fund is adequate, but allocate part of it to high liquidity low risk options."
        }
        return "Emergency fund coverage looks strong and has liquidity support."
    }

    private var investmentSummaryText: String {
        if investmentCount == 0 {
            return "No active investments found"
        }
        return "\(investmentCount) investments • \(highRiskInvestmentPercent)% high-risk exposure"
    }

    var investmentBalanceScore: Double { investmentHealthScore }

    private static func buildConcerns(
        savingsRate: Double,
        savings: Double,
        monthlyIncome: Double,
        grossIncome: Double,
        investmentCount: Int,
        investmentBreakdown: InvestmentRiskBreakdown,
        emergencyFund: Double,
        emergencyTarget: Double,
        insuranceCount: Int,
        hasHealth: Bool = false,
        hasLife: Bool = false,
        adultDependents: Int = 0,
        loanCount: Int,
        debtToIncomeRatio: Double
    ) -> [AssessmentConcern] {
        var cards: [AssessmentConcern] = []

        if monthlyIncome > 0 && savingsRate < Threshold.savingsRateTarget {
            cards.append(
                AssessmentConcern(
                    parameter: .vitals,
                    status: .concern,
                    title: "Savings below 30% benchmark",
                    summary: "Current savings rate is \((savingsRate * 100).rounded().safeInt)%, below the 30% target.",
                    recommendation: "Trim discretionary expenses and auto transfer savings to reach at least 30% each month."
                )
            )
        }

        if investmentCount == 0 {
            cards.append(
                AssessmentConcern(
                    parameter: .investment,
                    status: .concern,
                    title: "No investment allocation found",
                    summary: "You currently have no active investments in your assessment data.",
                    recommendation: "Start with a basic allocation and include a low risk bucket before increasing high risk exposure."
                )
            )
        } else {
            if investmentBreakdown.highRiskRatio >= Threshold.highRiskConcentration {
                cards.append(
                    AssessmentConcern(
                        parameter: .investment,
                        status: .concern,
                        title: "Portfolio is concentrated in high risk assets",
                        summary: "\((investmentBreakdown.highRiskRatio * 100).rounded().safeInt)% of your investments are high risk.",
                        recommendation: "Reduce concentration risk by diversifying into debt, deposits, or other lower volatility assets."
                    )
                )
            }

            let expectedInvestmentBuffer = max(0, savings * Threshold.lowInvestmentBufferMonths)
            if savingsRate >= Threshold.savingsRateTarget && investmentBreakdown.totalAmount < expectedInvestmentBuffer {
                cards.append(
                    AssessmentConcern(
                        parameter: .investment,
                        status: .watch,
                        title: "Savings are healthy but investments are still low",
                        summary: "Your savings trend is good, but deployed investments are lower than a 6 month savings buffer.",
                        recommendation: "Channel part of monthly savings into goal linked investments to build long-term wealth."
                    )
                )
            }
        }

        if emergencyTarget > 0 {
            if emergencyFund <= 0 {
                cards.append(
                    AssessmentConcern(
                        parameter: .emergencyFund,
                        status: .concern,
                        title: "Emergency fund not available",
                        summary: "No emergency corpus is recorded in your assessment.",
                                        recommendation: "Build an emergency fund of \(emergencyTarget.toCurrency(compact: true)) (about 6 months of essential expenses)."
                    )
                )
            } else if emergencyFund < emergencyTarget {
                let shortBy = emergencyTarget - emergencyFund
                cards.append(
                    AssessmentConcern(
                        parameter: .emergencyFund,
                        status: .watch,
                        title: "Emergency fund is under target",
                        summary: "Emergency corpus is short by \(shortBy.toCurrency(compact: true)) versus the 6-month essential-expense target.",
                        recommendation: "Top up gradually each month until you reach the full emergency fund target."
                    )
                )
            } else if investmentBreakdown.lowRiskLiquidAmount <= 0 {
                cards.append(
                    AssessmentConcern(
                        parameter: .emergencyFund,
                        status: .watch,
                        title: "Improve emergency fund liquidity",
                        summary: "Emergency corpus is adequate but not allocated to low-risk, high-liquidity instruments.",
                        recommendation: "Park a portion in Treasury Bills, Commercial Papers, or Sweep-in FDs for faster access with lower risk."
                    )
                )
            }
        }

        if !hasHealth && !hasLife {
            cards.append(
                AssessmentConcern(
                    parameter: .insurance,
                    status: .concern,
                    title: "Insurance coverage missing",
                    summary: "Neither health nor term life insurance is active in your profile.",
                    recommendation: "Prioritize getting a comprehensive health cover (₹5L–₹10L) first to protect savings from hospital bills."
                )
            )
        } else if !hasHealth {
            cards.append(
                AssessmentConcern(
                    parameter: .insurance,
                    status: .concern,
                    title: "Health insurance missing",
                    summary: "You have life cover, but no active health policy. Hospitalization costs could wipe out your savings.",
                    recommendation: "Secure a comprehensive family health insurance policy to safeguard your wealth."
                )
            )
        } else if !hasLife && adultDependents > 0 {
            cards.append(
                AssessmentConcern(
                    parameter: .insurance,
                    status: .watch,
                    title: "Term life insurance recommended",
                    summary: "You have \(adultDependents) dependent\(adultDependents == 1 ? "" : "s"), but no active term life cover is in place.",
                    recommendation: "Secure a pure term life policy with sum insured equal to 10× to 15× your annual income."
                )
            )
        }

        let totalEMI = debtToIncomeRatio * grossIncome

        if loanCount > 0 {
            if (totalEMI > savings && savings > 0) || (savings <= 0 && totalEMI > 0) {
                cards.append(
                    AssessmentConcern(
                        parameter: .liabilities,
                        status: .concern,
                        title: "Urgent: Loan structures are unachievable",
                        summary: savings <= 0 
                            ? "Your living expenses consume your entire income, leaving no margin to service \(totalEMI.toCurrency(compact: true)) in EMIs."
                            : "Your required EMIs (\(totalEMI.toCurrency(compact: true))) exceed your disposable monthly savings (\(savings.toCurrency(compact: true))).",
                        recommendation: "Use the Prepayment simulator to find a debt consolidation strategy or proactively increase your monthly savings margin."
                    )
                )
            } else if debtToIncomeRatio >= Threshold.stressedDebtToIncome {
                cards.append(
                    AssessmentConcern(
                        parameter: .liabilities,
                        status: .concern,
                        title: "Debt pressure is high",
                        summary: "Debt-to-income ratio is \((debtToIncomeRatio * 100).rounded().safeInt)%, which is elevated.",
                        recommendation: "Increase prepayments on high interest loans to bring debt-to-income under control."
                    )
                )
            } else if debtToIncomeRatio >= Threshold.healthyDebtToIncome {
                cards.append(
                    AssessmentConcern(
                        parameter: .liabilities,
                        status: .watch,
                        title: "Debt obligations need monitoring",
                        summary: "Debt to income ratio is \((debtToIncomeRatio * 100).rounded().safeInt)%.",
                        recommendation: "Keep EMIs within 30% of income where possible and avoid adding unsecured debt."
                    )
                )
            }
        }

        return cards
    }

    private static func monthlyNeedSafe(_ monthlyNeed: Double, fallbackIncome: Double) -> Double {
        if monthlyNeed > 1 { return monthlyNeed }
        if fallbackIncome > 0 { return fallbackIncome }
        return 1
    }

    private static func computeDebtToIncomeRatio(
        profile: AstraUserProfile?,
        data: CompleteAssessmentData?,
        grossIncome: Double
    ) -> Double {
        guard grossIncome > 0 else { return 0 }

        return FinancialHealthCalculations.computeDebtToIncomeRatio(profile: profile, data: data, grossIncome: grossIncome)
    }

    static func estimateEMI(for entry: AssessmentLoanEntry) -> Double {
        FinancialHealthCalculations.estimateEMI(for: entry)
    }

    private static func buildInvestmentBreakdown(from snapshots: [InvestmentSnapshot]) -> InvestmentRiskBreakdown {
        var high: Double = 0
        var medium: Double = 0
        var low: Double = 0
        var lowLiquid: Double = 0
        var highCount = 0

        snapshots.forEach { snapshot in
            switch snapshot.risk {
            case .high:
                high += snapshot.amount
                highCount += 1
            case .medium:
                medium += snapshot.amount
            case .low:
                low += snapshot.amount
            }

            if snapshot.isLowRiskLiquid {
                lowLiquid += snapshot.amount
            }
        }

        return InvestmentRiskBreakdown(
            highRiskAmount: high,
            mediumRiskAmount: medium,
            lowRiskAmount: low,
            lowRiskLiquidAmount: lowLiquid,
            highRiskCount: highCount
        )
    }

    private enum InvestmentRisk {
        case high
        case medium
        case low
    }

    private struct InvestmentSnapshot {
        let name: String
        let typeName: String
        let amount: Double
        let risk: InvestmentRisk
        let isLowRiskLiquid: Bool

        init(from investment: AstraInvestment) {
            name = investment.investmentName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            typeName = Self.canonicalTypeName(investment.investmentType)
            amount = max(0, investment.currentValue, investment.totalInvestedAmount, investment.investmentAmount)
            risk = Self.risk(for: investment.investmentType, name: name)
            isLowRiskLiquid = Self.isLowRiskLiquid(type: investment.investmentType, name: name)
        }

        init(from entry: AssessmentInvestmentEntry) {
            name = entry.fundName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            typeName = Self.canonicalTypeName(entry.type)
            amount = max(0, FinancialAssessmentInsights.parseNumber(entry.amount))
            risk = Self.risk(for: entry.type, name: name)
            isLowRiskLiquid = Self.isLowRiskLiquid(type: entry.type, name: name)
        }

        func matches(_ other: InvestmentSnapshot) -> Bool {
            guard typeName == other.typeName else { return false }
            if !name.isEmpty && !other.name.isEmpty && name == other.name {
                return true
            }
            return abs(amount - other.amount) < 1
        }

        private static func canonicalTypeName(_ type: AstraInvestmentType) -> String {
            switch type {
            case .mutualFund: return "mutualfund"
            case .stocks: return "stocks"
            case .goldETF, .physicalGold: return "gold"
            case .cryptocurrency: return "crypto"
            case .deposits, .cashSavings, .emergencyFund: return "deposits"
            case .ppf: return "ppf"
            case .nps: return "nps"
            case .bonds: return "bonds"
            case .realEstate: return "realestate"
            case .other: return "other"
            }
        }

        private static func canonicalTypeName(_ type: AssessmentInvestmentEntry.InvestmentType) -> String {
            switch type {
            case .mutualFund: return "mutualfund"
            case .stocks: return "stocks"
            case .gold: return "gold"
            case .crypto: return "crypto"
            case .bonds: return "bonds"
            case .ppf: return "ppf"
            case .nps: return "nps"
            case .realEstate: return "realestate"
            }
        }

        private static let highRiskKeywords = [
            "small cap", "mid cap", "midcap", "smallcap", "sector", "thematic", "crypto", "momentum"
        ]
        private static let lowRiskLiquidKeywords = [
            "liquid", "treasury", "t-bill", "t bill", "commercial paper", "money market", "overnight", "sweep", "ultra short", "gilt"
        ]

        private static func risk(for type: AstraInvestmentType, name: String) -> InvestmentRisk {
            switch type {
            case .stocks, .cryptocurrency:
                return .high
            case .deposits, .bonds, .cashSavings, .emergencyFund:
                return .low
            case .ppf:
                return .low
            case .mutualFund, .other:
                if containsAny(name, in: lowRiskLiquidKeywords) { return .low }
                if containsAny(name, in: highRiskKeywords) { return .high }
                return .medium
            case .goldETF, .physicalGold, .realEstate, .nps:
                return .medium
            }
        }

        private static func risk(for type: AssessmentInvestmentEntry.InvestmentType, name: String) -> InvestmentRisk {
            switch type {
            case .stocks, .crypto:
                return .high
            case .bonds, .ppf:
                return .low
            case .mutualFund:
                if containsAny(name, in: lowRiskLiquidKeywords) { return .low }
                if containsAny(name, in: highRiskKeywords) { return .high }
                return .medium
            case .nps, .gold, .realEstate:
                return .medium
            }
        }

        private static func isLowRiskLiquid(type: AstraInvestmentType, name: String) -> Bool {
            if [.deposits, .bonds, .cashSavings, .emergencyFund].contains(type) {
                return true
            }
            return containsAny(name, in: lowRiskLiquidKeywords)
        }

        private static func isLowRiskLiquid(type: AssessmentInvestmentEntry.InvestmentType, name: String) -> Bool {
            if type == .bonds {
                return true
            }
            return containsAny(name, in: lowRiskLiquidKeywords)
        }

        private static func containsAny(_ value: String, in keywords: [String]) -> Bool {
            keywords.contains { value.contains($0) }
        }
    }

    private static func parseNumber(_ value: String?) -> Double {
        guard let value else { return 0 }
        let cleaned = value
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "₹", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return max(0, Double(cleaned) ?? 0)
    }
}
