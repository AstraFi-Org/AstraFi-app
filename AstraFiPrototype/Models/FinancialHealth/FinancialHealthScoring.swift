import Foundation

enum FinancialHealthScoring {
    struct ParameterScore {
        let score: Double
        let isAssessed: Bool
    }

    static func calculateFinancialVitals(_ snapshot: FinancialHealthSnapshot) -> ParameterScore {
        guard snapshot.vitalsAssessed else { return ParameterScore(score: 0.55, isAssessed: false) }

        let savingsScore = FinancialHealthCalculations.clamp(snapshot.savingsRate / FinancialHealthWeights.savingsRateTarget)

        let expenseScore: Double
        if snapshot.expenseRatio <= 0.70 {
            expenseScore = 1.0 - (snapshot.expenseRatio / 0.70) * 0.20
        } else if snapshot.expenseRatio <= 1.0 {
            let t = (snapshot.expenseRatio - 0.70) / 0.30
            expenseScore = 0.80 - t * 0.55
        } else {
            expenseScore = 0.12
        }

        let surplusScore: Double
        if snapshot.monthlySurplus < 0 {
            surplusScore = 0.12
        } else if snapshot.monthlyIncome <= 0 {
            surplusScore = 0
        } else {
            surplusScore = FinancialHealthCalculations.clamp(snapshot.monthlySurplus / (snapshot.monthlyIncome * FinancialHealthWeights.savingsRateTarget))
        }

        var score: Double
        if let stability = snapshot.incomeStability {
            score = savingsScore * 0.40 + expenseScore * 0.20 + surplusScore * 0.25 + stability * 0.15
        } else {
            score = savingsScore * 0.50 + expenseScore * 0.20 + surplusScore * 0.30
        }

        if snapshot.monthlySurplus < 0 {
            score = min(score, 0.28)
        }
        return ParameterScore(score: FinancialHealthCalculations.clamp(score), isAssessed: true)
    }

    static func calculateDebtHealth(_ snapshot: FinancialHealthSnapshot) -> ParameterScore {
        guard snapshot.loanCount > 0, snapshot.debtToIncomeRatio > 0 else {
            return ParameterScore(score: 1.0, isAssessed: true)
        }

        let dti = snapshot.debtToIncomeRatio
        let dtiScore: Double
        if dti <= 0.20 {
            dtiScore = 1.0 - (dti / 0.20) * 0.10
        } else if dti <= 0.35 {
            let t = (dti - 0.20) / 0.15
            dtiScore = 0.90 - (t * 0.15)
        } else if dti <= 0.50 {
            let t = (dti - 0.35) / 0.15
            dtiScore = 0.75 - (t * 0.30)
        } else {
            let excess = min(0.35, dti - 0.50)
            dtiScore = max(0.10, 0.45 - (excess / 0.35) * 0.35)
        }

        let cashflowScore: Double
        if snapshot.monthlySurplus <= 0 {
            cashflowScore = 0.12
        } else if snapshot.emiToSurplusRatio >= 1 {
            cashflowScore = 0.22
        } else if snapshot.emiToSurplusRatio >= 0.6 {
            cashflowScore = 0.45
        } else if snapshot.emiToSurplusRatio >= 0.35 {
            cashflowScore = 0.70
        } else {
            cashflowScore = 0.92
        }

        let highInterestRatio = snapshot.outstandingDebt > 0 ? snapshot.highInterestDebtAmount / snapshot.outstandingDebt : 0
        let highInterestScore = snapshot.hasHighRiskDebt || highInterestRatio > 0.15
            ? max(0.35, 1.0 - highInterestRatio * 0.80)
            : 1.0

        let countScore: Double = snapshot.loanCount <= 2 ? 1.0 : snapshot.loanCount == 3 ? 0.85 : 0.70

        var score = dtiScore * 0.45
            + cashflowScore * 0.30
            + highInterestScore * 0.15
            + countScore * 0.10

        if snapshot.monthlySurplus <= 0 && snapshot.totalMonthlyEMI > 0 {
            score = min(score, 0.25)
        } else if snapshot.monthlySurplus > 0 && snapshot.totalMonthlyEMI > snapshot.monthlySurplus {
            score = min(score, 0.35)
        }

        return ParameterScore(score: FinancialHealthCalculations.clamp(max(0.10, score)), isAssessed: true)
    }

    static func calculateEmergencyReadiness(_ snapshot: FinancialHealthSnapshot) -> ParameterScore {
        guard snapshot.emergencyFundAssessed else {
            return ParameterScore(score: 0.55, isAssessed: false)
        }

        let coverage = snapshot.emergencyCoverageMonths
        let score: Double
        if coverage <= 0 {
            score = 0.12
        } else if coverage < 6 {
            score = FinancialHealthCalculations.clamp(coverage / FinancialHealthWeights.emergencyFundMonths)
        } else {
            score = min(1.0, 0.92 + min(0.08, (coverage - 6) / 12 * 0.08))
        }
        return ParameterScore(score: score, isAssessed: true)
    }

    static func calculateInvestmentHealth(_ snapshot: FinancialHealthSnapshot) -> ParameterScore {
        guard snapshot.investmentCount > 0, snapshot.investmentBreakdown.totalAmount > 0 else {
            return ParameterScore(score: 0.38, isAssessed: true)
        }

        let categoryBoost = snapshot.uniqueInvestmentCategories >= 3 ? 1.0 : snapshot.uniqueInvestmentCategories == 2 ? 0.82 : 0.58
        let countScore: Double = snapshot.investmentCount >= 3 ? 1.0 : snapshot.investmentCount == 2 ? 0.75 : 0.55
        let diversification = (categoryBoost * 0.55) + (countScore * 0.45)

        let highRatio = snapshot.investmentBreakdown.highRiskRatio
        let riskScore: Double
        if highRatio >= FinancialHealthWeights.highRiskConcentration {
            riskScore = 0.35
        } else {
            riskScore = 1.0 - (highRatio * 0.55)
        }

        let liquidRatio = snapshot.investmentBreakdown.lowRiskLiquidRatio
        let liquidityScore: Double = liquidRatio >= 0.15 ? 1.0 : liquidRatio > 0 ? 0.78 : 0.58

        let adequacy: Double
        if snapshot.goalTargetTotal > 0 {
            adequacy = FinancialHealthCalculations.clamp(snapshot.goalCurrentTotal / snapshot.goalTargetTotal)
        } else if snapshot.monthlySurplus > 0 {
            let gentleTarget = snapshot.monthlySurplus * 12
            adequacy = max(0.45, FinancialHealthCalculations.clamp(snapshot.investmentBreakdown.totalAmount / max(gentleTarget, 1)))
        } else {
            adequacy = snapshot.investmentBreakdown.totalAmount > 0 ? 0.55 : 0.38
        }

        let contributionScore: Double
        if snapshot.monthlySurplus > 0 {
            contributionScore = FinancialHealthCalculations.clamp(snapshot.monthlyInvestmentContribution / max(snapshot.monthlySurplus, 1))
        } else if snapshot.monthlyInvestmentContribution > 0 {
            contributionScore = 0.70
        } else {
            contributionScore = 0.45
        }

        let score = diversification * 0.25
            + riskScore * 0.30
            + liquidityScore * 0.15
            + adequacy * 0.20
            + contributionScore * 0.10

        return ParameterScore(score: FinancialHealthCalculations.clamp(max(0.12, score)), isAssessed: true)
    }

    static func calculateRiskProtection(_ snapshot: FinancialHealthSnapshot) -> ParameterScore {
        guard snapshot.insuranceAssessed else {
            return ParameterScore(score: 0.55, isAssessed: false)
        }

        let dependents = snapshot.adultDependents + snapshot.childDependents
        let healthScore: Double = snapshot.hasHealthInsurance ? 1.0 : 0.18
        var lifeScore: Double
        if snapshot.hasLifeInsurance {
            lifeScore = dependents > 0 ? 1.0 : 0.90
        } else {
            lifeScore = dependents > 0 ? 0.15 : 0.55
        }

        let targetCover = (snapshot.estimatedProtectionNeed != nil && (snapshot.estimatedProtectionNeed ?? 0) > 0)
            ? snapshot.estimatedProtectionNeed!
            : (snapshot.grossMonthlyIncome * 12 * FinancialHealthWeights.recommendedLifeCoverMultiple)
        let coverageScore: Double
        if targetCover > 0, dependents > 0 {
            coverageScore = FinancialHealthCalculations.clamp(snapshot.totalProtectionCoverage / targetCover)
        } else if snapshot.totalProtectionCoverage > 0 {
            coverageScore = 0.80
        } else if snapshot.hasHealthInsurance || snapshot.hasLifeInsurance {
            coverageScore = 0.50
        } else {
            coverageScore = 0.20
        }

        var score = healthScore * 0.40 + lifeScore * 0.40 + coverageScore * 0.20
        if !snapshot.hasHealthInsurance { score = min(score, 0.50) }
        if dependents > 0 && !snapshot.hasLifeInsurance { score = min(score, 0.42) }
        if !snapshot.hasHealthInsurance && !snapshot.hasLifeInsurance {
            score = snapshot.insuranceCount > 0 ? min(score, 0.40) : 0.18
        }

        return ParameterScore(score: FinancialHealthCalculations.clamp(score), isAssessed: true)
    }

    static func calculateOverallScore(
        vitals: ParameterScore,
        debt: ParameterScore,
        emergency: ParameterScore,
        investment: ParameterScore,
        protection: ParameterScore
    ) -> Double {
        let pairs: [(ParameterScore, Double)] = [
            (vitals, FinancialHealthWeights.financialVitals),
            (debt, FinancialHealthWeights.debtHealth),
            (emergency, FinancialHealthWeights.emergencyReadiness),
            (investment, FinancialHealthWeights.investmentHealth),
            (protection, FinancialHealthWeights.riskProtection)
        ]
        let assessed = pairs.filter(\.0.isAssessed)
        let source = assessed.isEmpty ? pairs : assessed
        let weightSum = source.reduce(0) { $0 + $1.1 }
        guard weightSum > 0 else { return 0 }
        let normalized = source.reduce(0) { $0 + $1.0.score * $1.1 } / weightSum
        return FinancialHealthCalculations.clamp(normalized * 100, 0, 100)
    }

    static func scores(for snapshot: FinancialHealthSnapshot) -> (
        vitals: ParameterScore,
        debt: ParameterScore,
        emergency: ParameterScore,
        investment: ParameterScore,
        protection: ParameterScore,
        overall: Double
    ) {
        let vitals = calculateFinancialVitals(snapshot)
        let debt = calculateDebtHealth(snapshot)
        let emergency = calculateEmergencyReadiness(snapshot)
        let investment = calculateInvestmentHealth(snapshot)
        let protection = calculateRiskProtection(snapshot)
        let overall = calculateOverallScore(
            vitals: vitals,
            debt: debt,
            emergency: emergency,
            investment: investment,
            protection: protection
        )
        return (vitals, debt, emergency, investment, protection, overall)
    }
}
