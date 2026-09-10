import Foundation

enum FinancialHealthSimulation {
    static func scenarios(from snapshot: FinancialHealthSnapshot, currentScore: Int) -> [FinancialHealthWhatIfScenario] {
        var items: [FinancialHealthWhatIfScenario] = []
        let monthlyNeed = max(snapshot.emergencyMonthlyNeed, 1)

        if snapshot.emergencyCoverageMonths < 6 {
            if snapshot.emergencyCoverageMonths < 3 {
                var threeMonths = snapshot
                threeMonths.emergencyFundAmount = monthlyNeed * 3
                threeMonths.emergencyCoverageMonths = 3
                threeMonths.emergencyGap = max(0, threeMonths.emergencyTarget - threeMonths.emergencyFundAmount)
                threeMonths.emergencyFundAssessed = true
                items.append(scenario(
                    id: "ef3",
                    title: "If emergency fund reaches 3 months",
                    detail: "Estimated if the reserve covers 3 months of essential expenses.",
                    snapshot: threeMonths,
                    currentScore: currentScore
                ))
            }
            var sixMonths = snapshot
            sixMonths.emergencyFundAmount = monthlyNeed * 6
            sixMonths.emergencyCoverageMonths = 6
            sixMonths.emergencyGap = 0
            sixMonths.emergencyFundAssessed = true
            items.append(scenario(
                id: "ef6",
                title: "If emergency fund reaches 6 months",
                detail: "Estimated if the reserve covers the 6-month target.",
                snapshot: sixMonths,
                currentScore: currentScore
            ))
        }

        if snapshot.vitalsAssessed, snapshot.savingsRate < FinancialHealthWeights.savingsRateTarget, snapshot.monthlyIncome > 0 {
            var improvedSavings = snapshot
            let targetSavings = snapshot.monthlyIncome * FinancialHealthWeights.savingsRateTarget
            improvedSavings.monthlySurplus = targetSavings
            improvedSavings.monthlyExpenses = snapshot.monthlyIncome - targetSavings
            improvedSavings.savingsRate = FinancialHealthWeights.savingsRateTarget
            improvedSavings.expenseRatio = improvedSavings.monthlyExpenses / snapshot.monthlyIncome
            improvedSavings.emiToSurplusRatio = targetSavings > 0 ? snapshot.totalMonthlyEMI / targetSavings : snapshot.emiToSurplusRatio
            items.append(scenario(
                id: "savings",
                title: "If savings rate reaches 30%",
                detail: "Estimated if monthly surplus reaches AstraFi's 30% benchmark. Debt and emergency amounts are left unchanged.",
                snapshot: improvedSavings,
                currentScore: currentScore
            ))
        }

        if snapshot.loanCount > 0, snapshot.debtToIncomeRatio > 0.20 {
            var lowerDebt = snapshot
            lowerDebt.debtToIncomeRatio = min(snapshot.debtToIncomeRatio, 0.20)
            lowerDebt.totalMonthlyEMI = lowerDebt.debtToIncomeRatio * max(snapshot.grossMonthlyIncome, 1)
            lowerDebt.emiToSurplusRatio = snapshot.monthlySurplus > 0 ? lowerDebt.totalMonthlyEMI / snapshot.monthlySurplus : 0
            lowerDebt.hasHighRiskDebt = false
            lowerDebt.highInterestDebtAmount = 0
            items.append(scenario(
                id: "debt",
                title: "If EMI burden falls to 20% DTI",
                detail: "Estimated if monthly EMI is brought within 20% of gross income. Cash-flow inputs stay the same unless surplus is already used in this scenario.",
                snapshot: lowerDebt,
                currentScore: currentScore
            ))
        }

        if snapshot.investmentCount == 0 || snapshot.investmentBreakdown.highRiskRatio >= 0.50 {
            var diversified = snapshot
            let total = max(snapshot.investmentBreakdown.totalAmount, max(snapshot.monthlySurplus * 6, 50_000))
            diversified.investmentCount = max(3, snapshot.investmentCount)
            diversified.uniqueInvestmentCategories = max(3, snapshot.uniqueInvestmentCategories)
            diversified.investmentBreakdown = InvestmentRiskBreakdown(
                highRiskAmount: total * 0.40,
                mediumRiskAmount: total * 0.35,
                lowRiskAmount: total * 0.25,
                lowRiskLiquidAmount: total * 0.20,
                highRiskCount: 1
            )
            diversified.monthlyInvestmentContribution = max(snapshot.monthlyInvestmentContribution, max(0, snapshot.monthlySurplus * 0.30))
            items.append(scenario(
                id: "invest",
                title: snapshot.investmentCount == 0 ? "If an investment allocation is added" : "If high-risk exposure is reduced",
                detail: snapshot.investmentCount == 0
                    ? "Estimated if a diversified allocation exists. Emergency fund and debt are left unchanged."
                    : "Estimated if higher-risk assets are closer to 40% of the portfolio.",
                snapshot: diversified,
                currentScore: currentScore
            ))
        }

        if snapshot.insuranceAssessed, !snapshot.hasHealthInsurance || !snapshot.hasLifeInsurance {
            var protected = snapshot
            protected.hasHealthInsurance = true
            protected.hasLifeInsurance = true
            protected.insuranceCount = max(2, snapshot.insuranceCount)
            protected.totalProtectionCoverage = max(
                snapshot.totalProtectionCoverage,
                snapshot.grossMonthlyIncome * 12 * FinancialHealthWeights.recommendedLifeCoverMultiple
            )
            items.append(scenario(
                id: "protect",
                title: "If health and life protection are in place",
                detail: "Estimated if core health and life cover is recorded. Other parameters are unchanged.",
                snapshot: protected,
                currentScore: currentScore
            ))
        }

        return Array(items.prefix(4))
    }

    private static func scenario(
        id: String,
        title: String,
        detail: String,
        snapshot: FinancialHealthSnapshot,
        currentScore: Int
    ) -> FinancialHealthWhatIfScenario {
        let estimated = FinancialHealthScoring.scores(for: snapshot).overall.rounded().safeInt
        return FinancialHealthWhatIfScenario(
            id: id,
            title: title,
            detail: detail,
            currentScore: currentScore,
            estimatedScore: estimated
        )
    }
}
