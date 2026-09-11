import Foundation

enum FinancialHealthPriorities {
    static func build(from parameters: [FinancialHealthParameterResult], snapshot: FinancialHealthSnapshot) -> [FinancialHealthPriorityItem] {
        let ranked = parameters
            .filter { $0.isAssessed && $0.status != .fine }
            .map { parameter -> (FinancialHealthParameterResult, Double) in
                (parameter, score(parameter, snapshot: snapshot))
            }
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                return lhs.0.score < rhs.0.score
            }
            .prefix(3)

        return ranked.enumerated().map { index, pair in
            let result = pair.0
            return FinancialHealthPriorityItem(
                id: result.parameter.rawValue,
                rank: index + 1,
                parameter: result.parameter,
                title: headline(for: result, snapshot: snapshot),
                reason: result.oneLineReason,
                impact: result.financialImpact,
                currentValue: currentValue(for: result, snapshot: snapshot),
                targetValue: targetValue(for: result, snapshot: snapshot),
                actionTitle: result.actionTitle,
                destination: result.actionDestination
            )
        }
    }

    private static func score(_ result: FinancialHealthParameterResult, snapshot: FinancialHealthSnapshot) -> Double {
        let weakness = (1 - result.score) * 40
        let severity: Double
        switch result.severity {
        case .critical: severity = 30
        case .high: severity = 24
        case .medium: severity = 14
        case .low: severity = 6
        case .none: severity = 0
        }
        let gap = gapFactor(result, snapshot: snapshot) * 18
        let downstream = downstreamFactor(result.parameter, snapshot: snapshot) * 12
        let urgency = urgencyFactor(result, snapshot: snapshot) * 16
        return weakness + severity + gap + downstream + urgency
    }

    private static func gapFactor(_ result: FinancialHealthParameterResult, snapshot: FinancialHealthSnapshot) -> Double {
        switch result.parameter {
        case .emergencyFund:
            return FinancialHealthCalculations.clamp(snapshot.emergencyGap / max(snapshot.emergencyTarget, 1))
        case .liabilities:
            return FinancialHealthCalculations.clamp(snapshot.debtToIncomeRatio / 0.50)
        case .vitals:
            return FinancialHealthCalculations.clamp((FinancialHealthWeights.savingsRateTarget - snapshot.savingsRate) / FinancialHealthWeights.savingsRateTarget)
        case .investment:
            return snapshot.investmentCount == 0 ? 0.7 : snapshot.investmentBreakdown.highRiskRatio
        case .insurance:
            let dependents = snapshot.adultDependents + snapshot.childDependents
            if dependents > 0 && !snapshot.hasLifeInsurance { return 0.9 }
            if !snapshot.hasHealthInsurance { return 0.8 }
            return 0.4
        }
    }

    private static func downstreamFactor(_ parameter: AssessmentParameter, snapshot: FinancialHealthSnapshot) -> Double {
        switch parameter {
        case .emergencyFund: return snapshot.emergencyCoverageMonths < 3 ? 1 : 0.6
        case .liabilities: return snapshot.monthlySurplus <= 0 || snapshot.debtToIncomeRatio >= 0.35 ? 0.95 : 0.5
        case .vitals: return snapshot.monthlySurplus <= 0 ? 0.9 : 0.55
        case .insurance:
            return snapshot.adultDependents + snapshot.childDependents > 0 ? 0.85 : 0.4
        case .investment: return 0.45
        }
    }

    private static func urgencyFactor(_ result: FinancialHealthParameterResult, snapshot: FinancialHealthSnapshot) -> Double {
        switch result.parameter {
        case .emergencyFund: return snapshot.emergencyCoverageMonths < 1.5 ? 1 : 0.6
        case .liabilities: return snapshot.monthlySurplus <= 0 ? 1 : 0.65
        case .insurance: return (!snapshot.hasHealthInsurance || (!snapshot.hasLifeInsurance && snapshot.adultDependents > 0)) ? 0.9 : 0.4
        case .vitals: return snapshot.monthlySurplus < 0 ? 0.85 : 0.4
        case .investment: return 0.35
        }
    }

    private static func headline(for result: FinancialHealthParameterResult, snapshot: FinancialHealthSnapshot) -> String {
        switch result.parameter {
        case .emergencyFund: return "Build Emergency Reserve"
        case .liabilities: return "Reduce Debt Pressure"
        case .insurance: return "Strengthen Protection"
        case .vitals: return snapshot.monthlySurplus < 0 ? "Restore Monthly Surplus" : "Improve Savings Rate"
        case .investment: return snapshot.investmentCount == 0 ? "Start Investment Allocation" : "Rebalance Investment Mix"
        }
    }

    private static func currentValue(for result: FinancialHealthParameterResult, snapshot: FinancialHealthSnapshot) -> String {
        switch result.parameter {
        case .emergencyFund: return snapshot.emergencyFundAmount.toCurrency(compact: true)
        case .liabilities: return "DTI \( (snapshot.debtToIncomeRatio * 100).rounded().safeInt )%"
        case .insurance: return snapshot.hasHealthInsurance || snapshot.hasLifeInsurance ? "Limited coverage" : "Coverage missing"
        case .vitals: return "Savings \((max(0, snapshot.savingsRate) * 100).rounded().safeInt)%"
        case .investment: return snapshot.investmentCount == 0 ? "No allocation" : "High-risk \((snapshot.investmentBreakdown.highRiskRatio * 100).rounded().safeInt)%"
        }
    }

    private static func targetValue(for result: FinancialHealthParameterResult, snapshot: FinancialHealthSnapshot) -> String {
        switch result.parameter {
        case .emergencyFund: return snapshot.emergencyTarget.toCurrency(compact: true)
        case .liabilities: return "DTI under 30%"
        case .insurance: return "Health + life cover"
        case .vitals: return "30% savings rate"
        case .investment: return "Balanced mix"
        }
    }
}
