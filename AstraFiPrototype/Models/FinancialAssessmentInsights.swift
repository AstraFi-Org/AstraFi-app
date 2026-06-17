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
        case .investment:    return "Investment"
        case .liabilities:   return "Liabilities"
        case .insurance:     return "Insurance"
        case .emergencyFund: return "Emergency Fund"
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
            // If we have new income, use it. For now assuming same as gross or we could apply tax.
            // AppStateManager uses the same value for both during update.
            takeHomeIncomeRaw = parseNumber(data.income)
        } else {
            takeHomeIncomeRaw = profile?.basicDetails.monthlyIncomeAfterTax ?? (grossIncome * (1.0 - AppStateManager.defaultTaxRate))
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

        let savings = max(0, takeHomeIncome - expenses)
        let savingsRate = takeHomeIncome > 0 ? min(1, savings / takeHomeIncome) : 0
        let emergencyTarget = grossIncome * Threshold.emergencyFundMonths
        let emergencyCoverage = emergencyTarget > 0 ? emergencyFund / emergencyTarget : 0

        // For investments, we prioritize assessment data if it has entries,
        // but if it's empty and a profile exists, we assume we want to see the profile's investments.
        // If we are in the middle of an assessment and the user hasn't reached investments yet,
        // data?.investmentEntries might be empty.
        
        let profileSnapshots = profile?.investments.map { InvestmentSnapshot(from: $0) } ?? []
        let assessmentSnapshots = data?.investmentEntries.map { InvestmentSnapshot(from: $0) } ?? []
        
        // If assessment has data, use it. Otherwise fallback to profile.
        let sourceSnapshots = (data != nil && !assessmentSnapshots.isEmpty) ? assessmentSnapshots : profileSnapshots

        let investmentCount = sourceSnapshots.count
        let investmentBreakdown = buildInvestmentBreakdown(from: sourceSnapshots)

        // Loans and Insurance: Similar logic - prioritize assessment entries if they exist
        let loanCount: Int
        if let data = data, !data.loanEntries.isEmpty {
            loanCount = data.loanEntries.count
        } else {
            loanCount = profile?.loans.count ?? 0
        }
        
        let insuranceCount: Int
        if let data = data, !data.insuranceEntries.isEmpty {
            insuranceCount = data.insuranceEntries.count
        } else {
            insuranceCount = profile?.insurances.count ?? 0
        }

        let debtRatio = computeDebtToIncomeRatio(profile: profile, data: data, grossIncome: grossIncome)
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
            concerns: concerns
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
        if concerns.contains(where: { $0.parameter == parameter && $0.status == .concern }) {
            return .concern
        }
        if concerns.contains(where: { $0.parameter == parameter && $0.status == .watch }) {
            return .watch
        }
        return .fine
    }

    var parameterSummaries: [AssessmentParameterSummary] {
        [
            AssessmentParameterSummary(
                parameter: .vitals,
                description: "You save \(savingRatioPercent)% of your monthly income",
                status: status(for: .vitals)
            ),
            AssessmentParameterSummary(
                parameter: .investment,
                description: investmentSummaryText,
                status: status(for: .investment)
            ),
            AssessmentParameterSummary(
                parameter: .liabilities,
                description: loanCount == 0 ? "No active loans" : "\(loanCount) active loan\(loanCount == 1 ? "" : "s")",
                status: status(for: .liabilities)
            ),
            AssessmentParameterSummary(
                parameter: .insurance,
                description: insuranceCount == 0 ? "No active insurance policies" : "\(insuranceCount) active polic\(insuranceCount == 1 ? "y" : "ies")",
                status: status(for: .insurance)
            ),
            AssessmentParameterSummary(
                parameter: .emergencyFund,
                description: "Emergency corpus \(emergencyFundAmount.toCurrency(compact: true)) / \(emergencyFundTarget.toCurrency(compact: true))",
                status: status(for: .emergencyFund)
            ),
        ]
    }

    var radarValues: [(String, Double, Double)] {
        [
            ("Income Stability",    hasFixedIncome ? 0.95 : 0.65, 0.8),
            ("Saving Discipline",   min(1.0, savingsRate / 0.3), 0.7),
            ("Emergency Readiness", min(1.0, emergencyCoverageRatio), 0.75),
            ("Investment Balance",  investmentBalanceScore, 0.65),
            ("Risk Protection",     insuranceCount >= 2 ? 0.9 : (insuranceCount == 1 ? 0.65 : 0.2), 0.55),
        ]
    }

    var emergencyStatusMessage: String {
        if emergencyFundAmount <= 0 {
            return "No emergency fund found. Target at least \(emergencyFundTarget.toCurrency(compact: true)) (6× income)."
        }
        if emergencyFundAmount < emergencyFundTarget {
            let shortBy = emergencyFundTarget - emergencyFundAmount
            return "Emergency fund is partial, increase by \(shortBy.toCurrency(compact: true)) to reach 6× monthly income."
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

    var investmentBalanceScore: Double {
        guard investmentBreakdown.totalAmount > 0 else { return 0.1 }
        let diversificationScore: Double = investmentCount >= 3 ? 1.0 : (investmentCount == 2 ? 0.75 : 0.55)
        let riskScore: Double = investmentBreakdown.highRiskRatio >= Threshold.highRiskConcentration ? 0.35 : 1.0 - (investmentBreakdown.highRiskRatio * 0.5)
        let liquidityScore: Double = investmentBreakdown.lowRiskLiquidAmount > 0 ? 1.0 : 0.65
        return max(0.1, min(1.0, diversificationScore * riskScore * liquidityScore))
    }

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
                        recommendation: "Build an emergency fund of \(emergencyTarget.toCurrency(compact: true)) (6× monthly income)."
                    )
                )
            } else if emergencyFund < emergencyTarget {
                let shortBy = emergencyTarget - emergencyFund
                cards.append(
                    AssessmentConcern(
                        parameter: .emergencyFund,
                        status: .watch,
                        title: "Emergency fund is under target",
                        summary: "Emergency corpus is short by \(shortBy.toCurrency(compact: true)) versus the 6× income target.",
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

        if insuranceCount == 0 {
            cards.append(
                AssessmentConcern(
                    parameter: .insurance,
                    status: .concern,
                    title: "Insurance coverage missing",
                    summary: "No active insurance policy is mapped in your profile.",
                    recommendation: "Prioritize health and life coverage to protect your savings and dependents."
                )
            )
        }

        let totalEMI = debtToIncomeRatio * grossIncome

        if loanCount > 0 {
            if totalEMI > savings && savings > 0 {
                cards.append(
                    AssessmentConcern(
                        parameter: .liabilities,
                        status: .concern,
                        title: "Urgent: Loan structures are unachievable",
                        summary: "Your required EMIs (\(totalEMI.toCurrency(compact: true))) exceed your disposable monthly savings.",
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

        _ = grossIncome // Keep available for future policy variants while preserving function signature.
        return cards
    }

    private static func computeDebtToIncomeRatio(
        profile: AstraUserProfile?,
        data: CompleteAssessmentData?,
        grossIncome: Double
    ) -> Double {
        guard grossIncome > 0 else { return 0 }

        let totalEMI: Double
        if let data = data, !data.loanEntries.isEmpty {
            totalEMI = data.loanEntries.reduce(0) { $0 + estimateEMI(for: $1) }
        } else if let profile = profile {
            totalEMI = profile.loans.reduce(0) { $0 + max(0, $1.calculatedEMI) }
        } else {
            totalEMI = 0
        }

        return max(0, min(1, totalEMI / grossIncome))
    }

    private static func estimateEMI(for entry: AssessmentLoanEntry) -> Double {
        let principal = parseNumber(entry.amount)
        let annualRate = parseNumber(entry.interestRate) / 100
        let tenureYears = parseNumber(entry.tenure)
        let months = max(1, ((tenureYears > 0 ? tenureYears : 1) * 12).safeInt)

        guard principal > 0 else { return 0 }
        if annualRate <= 0 {
            return principal / Double(months)
        }

        let monthlyRate = annualRate / 12
        let growth = pow(1 + monthlyRate, Double(months))
        guard (growth - 1) != 0 else { return principal / Double(months) }
        let emi = (principal * monthlyRate * growth) / (growth - 1)
        return emi.isFinite ? max(0, emi) : 0
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
        let amount: Double
        let risk: InvestmentRisk
        let isLowRiskLiquid: Bool

        init(from investment: AstraInvestment) {
            amount = max(0, investment.currentValue)
            let name = investment.investmentName.lowercased()
            risk = Self.risk(for: investment.investmentType, name: name)
            isLowRiskLiquid = Self.isLowRiskLiquid(type: investment.investmentType, name: name)
        }

        init(from entry: AssessmentInvestmentEntry) {
            amount = max(0, FinancialAssessmentInsights.parseNumber(entry.amount))
            let name = entry.fundName.lowercased()
            risk = Self.risk(for: entry.type, name: name)
            isLowRiskLiquid = Self.isLowRiskLiquid(type: entry.type, name: name)
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
            case .deposits, .bonds:
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
            if [.deposits, .bonds].contains(type) {
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
