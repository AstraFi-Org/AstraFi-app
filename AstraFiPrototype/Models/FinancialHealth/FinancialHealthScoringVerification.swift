import Foundation

enum FinancialHealthScoringVerification {
    struct CaseResult {
        let name: String
        let passed: Bool
        let detail: String
    }

    static func run() -> [CaseResult] {
        [
            case1StrongFinances(),
            case2PoorEmergency(),
            case3HighDebt(),
            case4HighRiskInvestments(),
            case5NoInsuranceWithDependents(),
            case6ZeroDebt(),
            case7NoInvestments(),
            missingDataNotPunishedAsZero(),
            whatIfDoesNotDoubleCount()
        ]
    }

    static func allPassed() -> Bool {
        run().allSatisfy(\.passed)
    }

    private static func base() -> FinancialHealthSnapshot {
        FinancialHealthSnapshot(
            monthlyIncome: 80_000,
            grossMonthlyIncome: 100_000,
            monthlyExpenses: 50_000,
            monthlySurplus: 30_000,
            savingsRate: 0.375,
            expenseRatio: 0.625,
            incomeStability: nil,
            vitalsAssessed: true,
            hasFixedIncome: true,
            emergencyFundAmount: 300_000,
            emergencyFundAssessed: true,
            essentialMonthlyExpenses: 50_000,
            emergencyMonthlyNeed: 50_000,
            emergencyTarget: 300_000,
            emergencyCoverageMonths: 6,
            emergencyGap: 0,
            emergencyTargetIsEstimate: false,
            loanCount: 1,
            totalMonthlyEMI: 15_000,
            outstandingDebt: 500_000,
            debtToIncomeRatio: 0.15,
            emiToSurplusRatio: 0.5,
            hasHighRiskDebt: false,
            highInterestDebtAmount: 0,
            remainingInterestEstimate: nil,
            debtFreeDate: nil,
            investmentBreakdown: InvestmentRiskBreakdown(
                highRiskAmount: 80_000,
                mediumRiskAmount: 80_000,
                lowRiskAmount: 80_000,
                lowRiskLiquidAmount: 50_000,
                highRiskCount: 1
            ),
            investmentCount: 4,
            uniqueInvestmentCategories: 3,
            monthlyInvestmentContribution: 15_000,
            investmentAssessed: true,
            goalTargetTotal: 0,
            goalCurrentTotal: 0,
            insuranceCount: 2,
            hasHealthInsurance: true,
            hasLifeInsurance: true,
            adultDependents: 1,
            childDependents: 0,
            totalProtectionCoverage: 10_000_000,
            insuranceAssessed: true
        )
    }

    private static func case1StrongFinances() -> CaseResult {
        let scores = FinancialHealthScoring.scores(for: base())
        let overall = scores.overall
        let passed = overall >= 75
            && scores.vitals.score >= 0.7
            && scores.debt.score >= 0.8
            && scores.emergency.score >= 0.9
            && scores.protection.score >= 0.8
        return CaseResult(name: "Strong finances", passed: passed, detail: "overall \(Int(overall.rounded()))")
    }

    private static func case2PoorEmergency() -> CaseResult {
        var snapshot = base()
        snapshot.monthlyExpenses = 70_000
        snapshot.monthlySurplus = 10_000
        snapshot.savingsRate = 0.125
        snapshot.expenseRatio = 0.875
        snapshot.emergencyFundAmount = 40_000
        snapshot.emergencyCoverageMonths = 40_000 / 70_000
        snapshot.emergencyGap = snapshot.emergencyTarget - 40_000
        let scores = FinancialHealthScoring.scores(for: snapshot)
        let parameters = FinancialHealthDiagnostics.build(snapshot: snapshot, scores: scores)
        let priorities = FinancialHealthPriorities.build(from: parameters, snapshot: snapshot)
        let passed = scores.emergency.score < 0.4
            && scores.vitals.score < 0.7
            && (priorities.first?.parameter == .emergencyFund || scores.emergency.score < scores.vitals.score)
        return CaseResult(name: "Poor emergency readiness", passed: passed, detail: "emergency \(String(format: "%.1f", scores.emergency.score * 10))")
    }

    private static func case3HighDebt() -> CaseResult {
        var snapshot = base()
        snapshot.loanCount = 3
        snapshot.totalMonthlyEMI = 42_000
        snapshot.debtToIncomeRatio = 0.42
        snapshot.emiToSurplusRatio = 1.4
        snapshot.monthlySurplus = 20_000
        snapshot.hasHighRiskDebt = true
        snapshot.highInterestDebtAmount = 400_000
        snapshot.outstandingDebt = 1_480_000
        let scores = FinancialHealthScoring.scores(for: snapshot)
        let parameters = FinancialHealthDiagnostics.build(snapshot: snapshot, scores: scores)
        let priorities = FinancialHealthPriorities.build(from: parameters, snapshot: snapshot)
        let passed = scores.debt.score < 0.55 && priorities.contains(where: { $0.parameter == .liabilities })
        return CaseResult(name: "High debt", passed: passed, detail: "debt \(String(format: "%.1f", scores.debt.score * 10))")
    }

    private static func case4HighRiskInvestments() -> CaseResult {
        var snapshot = base()
        snapshot.investmentBreakdown = InvestmentRiskBreakdown(
            highRiskAmount: 240_000,
            mediumRiskAmount: 20_000,
            lowRiskAmount: 0,
            lowRiskLiquidAmount: 0,
            highRiskCount: 3
        )
        snapshot.investmentCount = 3
        snapshot.uniqueInvestmentCategories = 1
        let scores = FinancialHealthScoring.scores(for: snapshot)
        let passed = scores.investment.score < FinancialHealthScoring.scores(for: base()).investment.score
        return CaseResult(name: "High-risk concentration", passed: passed, detail: "investment \(String(format: "%.1f", scores.investment.score * 10))")
    }

    private static func case5NoInsuranceWithDependents() -> CaseResult {
        var snapshot = base()
        snapshot.hasHealthInsurance = false
        snapshot.hasLifeInsurance = false
        snapshot.insuranceCount = 0
        snapshot.totalProtectionCoverage = 0
        snapshot.adultDependents = 2
        let scores = FinancialHealthScoring.scores(for: snapshot)
        let parameters = FinancialHealthDiagnostics.build(snapshot: snapshot, scores: scores)
        let priorities = FinancialHealthPriorities.build(from: parameters, snapshot: snapshot)
        let passed = scores.protection.score < 0.35 && priorities.contains(where: { $0.parameter == .insurance })
        return CaseResult(name: "No insurance with dependents", passed: passed, detail: "protection \(String(format: "%.1f", scores.protection.score * 10))")
    }

    private static func case6ZeroDebt() -> CaseResult {
        var snapshot = base()
        snapshot.loanCount = 0
        snapshot.totalMonthlyEMI = 0
        snapshot.debtToIncomeRatio = 0
        snapshot.outstandingDebt = 0
        snapshot.emiToSurplusRatio = 0
        let scores = FinancialHealthScoring.scores(for: snapshot)
        let passed = scores.debt.score >= 0.99
        return CaseResult(name: "Zero debt", passed: passed, detail: "debt \(String(format: "%.1f", scores.debt.score * 10))")
    }

    private static func case7NoInvestments() -> CaseResult {
        var snapshot = base()
        snapshot.investmentCount = 0
        snapshot.investmentBreakdown = InvestmentRiskBreakdown(
            highRiskAmount: 0, mediumRiskAmount: 0, lowRiskAmount: 0, lowRiskLiquidAmount: 0, highRiskCount: 0
        )
        snapshot.monthlyInvestmentContribution = 0
        let scores = FinancialHealthScoring.scores(for: snapshot)
        let parameters = FinancialHealthDiagnostics.build(snapshot: snapshot, scores: scores)
        let investment = parameters.first { $0.parameter == .investment }
        let passed = scores.investment.score > 0.2
            && scores.investment.score < 0.5
            && (investment?.oneLineReason.contains("No investment") ?? false)
        return CaseResult(name: "No investments", passed: passed, detail: investment?.oneLineReason ?? "")
    }

    private static func missingDataNotPunishedAsZero() -> CaseResult {
        var snapshot = base()
        snapshot.insuranceAssessed = false
        snapshot.hasHealthInsurance = false
        snapshot.hasLifeInsurance = false
        snapshot.emergencyFundAssessed = false
        snapshot.emergencyFundAmount = 0
        snapshot.emergencyCoverageMonths = 0
        let scores = FinancialHealthScoring.scores(for: snapshot)
        let passed = scores.protection.isAssessed == false
            && scores.emergency.isAssessed == false
            && scores.protection.score > 0.3
            && scores.overall > 50
        return CaseResult(name: "Missing data not treated as zero", passed: passed, detail: "overall \(Int(scores.overall.rounded()))")
    }

    private static func whatIfDoesNotDoubleCount() -> CaseResult {
        var snapshot = base()
        snapshot.emergencyFundAmount = 50_000
        snapshot.emergencyCoverageMonths = 1
        snapshot.emergencyGap = snapshot.emergencyTarget - 50_000
        let current = FinancialHealthScoring.scores(for: snapshot)
        var improved = snapshot
        improved.emergencyFundAmount = snapshot.emergencyMonthlyNeed * 6
        improved.emergencyCoverageMonths = 6
        improved.emergencyGap = 0
        let after = FinancialHealthScoring.scores(for: improved)
        let investmentUnchanged = abs(current.investment.score - after.investment.score) < 0.0001
        let debtUnchanged = abs(current.debt.score - after.debt.score) < 0.0001
        let emergencyImproved = after.emergency.score > current.emergency.score
        return CaseResult(
            name: "What-if does not double-count",
            passed: investmentUnchanged && debtUnchanged && emergencyImproved,
            detail: "\(Int(current.overall.rounded())) → \(Int(after.overall.rounded()))"
        )
    }
}
