import Foundation

enum FinancialHealthDiagnostics {
    static func status(for score: Double, assessed: Bool) -> AssessmentParameterStatus {
        guard assessed else { return .watch }
        let outOf100 = score * 100
        if outOf100 < 40 { return .critical }
        if outOf100 < 60 { return .concern }
        if outOf100 < 75 { return .watch }
        return .fine
    }

    static func severity(for score: Double, assessed: Bool, impactBoost: Bool) -> FinancialHealthSeverity {
        guard assessed else { return .none }
        let outOf10 = score * 10
        if outOf10 < 4 { return impactBoost ? .critical : .high }
        if outOf10 < 6 { return impactBoost ? .high : .medium }
        if outOf10 < 7.5 { return .medium }
        return .low
    }

    static func priorityLevel(from severity: FinancialHealthSeverity) -> FinancialHealthPriorityLevel {
        switch severity {
        case .critical: return .critical
        case .high: return .high
        case .medium: return .medium
        case .low, .none: return .low
        }
    }

    static func percent(_ value: Double) -> String {
        "\((value * 100).rounded().safeInt)%"
    }

    static func months(_ value: Double) -> String {
        String(format: "%.1f months", max(0, value))
    }

    static func build(
        snapshot: FinancialHealthSnapshot,
        scores: (
            vitals: FinancialHealthScoring.ParameterScore,
            debt: FinancialHealthScoring.ParameterScore,
            emergency: FinancialHealthScoring.ParameterScore,
            investment: FinancialHealthScoring.ParameterScore,
            protection: FinancialHealthScoring.ParameterScore,
            overall: Double
        )
    ) -> [FinancialHealthParameterResult] {
        let overall = scores.overall
        return [
            vitals(snapshot, scores.vitals, overall: overall),
            debt(snapshot, scores.debt, overall: overall),
            emergency(snapshot, scores.emergency, overall: overall),
            investment(snapshot, scores.investment, overall: overall),
            protection(snapshot, scores.protection, overall: overall)
        ]
    }

    private static func pack(
        parameter: AssessmentParameter,
        score: FinancialHealthScoring.ParameterScore,
        overall: Double,
        metrics: [FinancialHealthMetric],
        why: String,
        impact: String,
        action: String,
        affected: [String],
        reason: String,
        actionTitle: String,
        destination: FinancialHealthActionDestination,
        impactBoost: Bool
    ) -> FinancialHealthParameterResult {
        let outOf10 = score.score * 10
        let severity = severity(for: score.score, assessed: score.isAssessed, impactBoost: impactBoost)
        let status = status(for: score.score, assessed: score.isAssessed)
        let possible = FinancialHealthWeights.weight(for: parameter) * 100
        let contribution = score.isAssessed ? score.score * possible : 0
        let potential = score.isAssessed ? max(0, (1 - score.score) * possible) : 0
        return FinancialHealthParameterResult(
            parameter: parameter,
            score: score.score,
            scoreOutOf10: outOf10,
            isAssessed: score.isAssessed,
            status: status,
            statusTitle: score.isAssessed ? FinancialHealthStatusBand.parameterTitle(for: outOf10) : "Needs information",
            severity: severity,
            metrics: metrics,
            whyItMatters: why,
            financialImpact: impact,
            recommendedAction: action,
            affectedAreas: affected,
            oneLineReason: reason,
            priority: priorityLevel(from: severity),
            improvementPotential: potential,
            actionTitle: actionTitle,
            actionDestination: destination,
            contributionPoints: contribution,
            possiblePoints: possible
        )
    }

    private static func vitals(_ snapshot: FinancialHealthSnapshot, _ score: FinancialHealthScoring.ParameterScore, overall: Double) -> FinancialHealthParameterResult {
        let savingsPct = percent(max(0, snapshot.savingsRate))
        var metrics = [
            FinancialHealthMetric(id: "income", label: "Income", value: snapshot.monthlyIncome.toCurrency(compact: true)),
            FinancialHealthMetric(id: "expenses", label: "Expenses", value: snapshot.monthlyExpenses.toCurrency(compact: true)),
            FinancialHealthMetric(id: "surplus", label: "Monthly Surplus", value: snapshot.monthlySurplus.toCurrency(compact: true)),
            FinancialHealthMetric(id: "savings", label: "Savings Rate", value: savingsPct),
            FinancialHealthMetric(id: "expenseRatio", label: "Expense Ratio", value: percent(snapshot.expenseRatio))
        ]
        if let stability = snapshot.incomeStability {
            metrics.append(FinancialHealthMetric(id: "stability", label: "Income Stability", value: percent(stability)))
        }

        let why: String
        let impact: String
        let action: String
        let reason: String
        if !score.isAssessed {
            why = "Income and expense details are needed before AstraFi can assess cash-flow health."
            impact = "Without cash-flow information, surplus, savings capacity, and related scores cannot be evaluated."
            action = "Add your monthly income and expenses to complete Financial Vitals."
            reason = "Income and expense information is missing."
        } else if snapshot.monthlySurplus < 0 {
            why = "Monthly expenses currently exceed take-home income, leaving a negative surplus of \(snapshot.monthlySurplus.toCurrency(compact: true))."
            impact = "A negative surplus can slow emergency-fund growth, reduce investment contributions, and make it harder to stay on track with financial goals."
            action = "Review essential versus discretionary spending to restore a monthly surplus."
            reason = "Monthly expenses exceed income."
        } else if snapshot.savingsRate >= FinancialHealthWeights.savingsRateTarget {
            why = "Your savings rate is \(savingsPct), which is at or above AstraFi's 30% benchmark."
            impact = "A healthy surplus can support emergency reserves, investments, and goal funding."
            action = "Keep directing surplus toward reserves and goal-linked investing."
            reason = "Your savings rate is above AstraFi's 30% benchmark."
        } else {
            why = "Your savings rate is \(savingsPct), below AstraFi's 30% benchmark, and expenses consume \(percent(snapshot.expenseRatio)) of income."
            impact = "A lower surplus may affect emergency fund growth, investment contributions, and goal achievement."
            action = "Improve monthly surplus by reviewing expenses and keeping a consistent savings transfer."
            reason = "Savings rate is \(savingsPct), below the 30% benchmark."
        }

        return pack(
            parameter: .vitals,
            score: score,
            overall: overall,
            metrics: metrics,
            why: why,
            impact: impact,
            action: action,
            affected: ["Emergency fund growth", "Investment contributions", "Goal achievement"],
            reason: reason,
            actionTitle: "Review Cash Flow",
            destination: .vitals,
            impactBoost: snapshot.monthlySurplus <= 0
        )
    }

    private static func debt(_ snapshot: FinancialHealthSnapshot, _ score: FinancialHealthScoring.ParameterScore, overall: Double) -> FinancialHealthParameterResult {
        let dtiPct = percent(snapshot.debtToIncomeRatio)
        let emiSurplusText = snapshot.loanCount == 0
            ? "0%"
            : snapshot.monthlySurplus <= 0 ? "Severe" : percent(min(snapshot.emiToSurplusRatio, 9.99))
        var metrics = [
            FinancialHealthMetric(id: "dti", label: "DTI", value: dtiPct),
            FinancialHealthMetric(id: "emi", label: "Monthly EMI", value: snapshot.totalMonthlyEMI.toCurrency(compact: true)),
            FinancialHealthMetric(id: "outstanding", label: "Outstanding Debt", value: snapshot.outstandingDebt.toCurrency(compact: true)),
            FinancialHealthMetric(id: "emiSurplus", label: "EMI-to-Surplus", value: emiSurplusText),
            FinancialHealthMetric(id: "loans", label: "Active Loans", value: "\(snapshot.loanCount)")
        ]
        if let remaining = snapshot.remainingInterestEstimate {
            metrics.append(FinancialHealthMetric(id: "interest", label: "Remaining Interest (est.)", value: remaining.toCurrency(compact: true)))
        }
        if let date = snapshot.debtFreeDate {
            metrics.append(FinancialHealthMetric(id: "debtFree", label: "Debt-Free Date", value: date.formatted(.dateTime.month().year())))
        }

        let why: String
        let impact: String
        let action: String
        let reason: String
        if snapshot.loanCount == 0 {
            why = "No active debt obligations were detected."
            impact = "With no EMI commitments, more of your income can support savings, reserves, and investments."
            action = "Keep new borrowing aligned with your surplus and goals."
            reason = "No active debt obligations detected."
        } else {
            why = "Your EMIs consume \(dtiPct) of gross income\(snapshot.hasHighRiskDebt ? " and include higher-interest debt" : "")."
            impact = "High debt commitments can reduce monthly financial flexibility and the amount available for savings and investing."
            action = "Review loan EMIs and consider reducing higher-interest balances first."
            reason = snapshot.monthlySurplus <= 0
                ? "EMIs are running against a zero or negative surplus."
                : "EMI commitments consume \(dtiPct) of gross monthly income."
        }

        return pack(
            parameter: .liabilities,
            score: score,
            overall: overall,
            metrics: metrics,
            why: why,
            impact: impact,
            action: action,
            affected: ["Monthly cash flow", "Savings capacity", "Investment capacity", "Financial flexibility"],
            reason: reason,
            actionTitle: "Analyze Loans",
            destination: .loanTracker,
            impactBoost: snapshot.debtToIncomeRatio >= FinancialHealthWeights.stressedDebtToIncome || snapshot.monthlySurplus <= 0
        )
    }

    private static func emergency(_ snapshot: FinancialHealthSnapshot, _ score: FinancialHealthScoring.ParameterScore, overall: Double) -> FinancialHealthParameterResult {
        let coverageText = months(snapshot.emergencyCoverageMonths)
        let metrics = [
            FinancialHealthMetric(id: "fund", label: "Emergency Fund", value: snapshot.emergencyFundAmount.toCurrency(compact: true)),
            FinancialHealthMetric(id: "coverage", label: "Coverage", value: coverageText),
            FinancialHealthMetric(id: "target", label: "Target", value: "6 months"),
            FinancialHealthMetric(id: "gap", label: "Gap", value: snapshot.emergencyGap.toCurrency(compact: true)),
            FinancialHealthMetric(id: "need", label: snapshot.emergencyTargetIsEstimate ? "Monthly need (estimate)" : "Essential expenses", value: snapshot.emergencyMonthlyNeed.toCurrency(compact: true))
        ]

        let why: String
        let impact: String
        let action: String
        let reason: String
        if !score.isAssessed {
            why = "Emergency fund information has not been provided yet, so this area is not fully assessed."
            impact = "Without a recorded reserve, AstraFi cannot estimate how long essential expenses could be covered."
            action = "Add your current emergency reserve to complete this assessment."
            reason = "Emergency fund information is needed."
        } else if snapshot.emergencyCoverageMonths >= 6 {
            why = "Your emergency reserve covers about \(coverageText) of essential expenses, which meets the 6-month target."
            impact = "A funded reserve can reduce the need to use investments or borrow during an income disruption."
            action = "Keep the reserve accessible and review it as expenses change."
            reason = "Emergency coverage meets the 6-month target."
        } else {
            why = "Your emergency fund currently covers only \(coverageText) of essential expenses, while your target is 6 months."
            impact = "If income is interrupted or an unexpected expense occurs, you may need to use investments or take on additional debt."
            action = "Build your emergency reserve by approximately \(snapshot.emergencyGap.toCurrency(compact: true))."
            reason = "Your emergency fund covers only \(coverageText)."
        }

        return pack(
            parameter: .emergencyFund,
            score: score,
            overall: overall,
            metrics: metrics,
            why: why,
            impact: impact,
            action: action,
            affected: ["Ability to handle unexpected expenses", "Dependence on loans or credit", "Ability to continue investments during emergencies", "Financial goal stability"],
            reason: reason,
            actionTitle: "Build Emergency Fund",
            destination: .emergencyPlanner,
            impactBoost: snapshot.emergencyCoverageMonths < 3
        )
    }

    private static func investment(_ snapshot: FinancialHealthSnapshot, _ score: FinancialHealthScoring.ParameterScore, overall: Double) -> FinancialHealthParameterResult {
        let highRiskPct = percent(snapshot.investmentBreakdown.highRiskRatio)
        let diversification = FinancialHealthCalculations.diversificationLabel(
            count: snapshot.investmentCount,
            categories: snapshot.uniqueInvestmentCategories
        )
        let metrics = [
            FinancialHealthMetric(id: "total", label: "Total Investments", value: snapshot.investmentBreakdown.totalAmount.toCurrency(compact: true)),
            FinancialHealthMetric(id: "sip", label: "Monthly Contribution", value: snapshot.monthlyInvestmentContribution.toCurrency(compact: true)),
            FinancialHealthMetric(id: "highRisk", label: "High-Risk Exposure", value: highRiskPct),
            FinancialHealthMetric(id: "div", label: "Diversification", value: diversification),
            FinancialHealthMetric(id: "liquid", label: "Liquid Investments", value: snapshot.investmentBreakdown.lowRiskLiquidAmount.toCurrency(compact: true))
        ]

        let why: String
        let impact: String
        let action: String
        let reason: String
        if snapshot.investmentCount == 0 {
            why = "No investment allocation is recorded yet."
            impact = "Without invested surplus, medium- and long-term goals may progress more slowly."
            action = "Review whether a portion of surplus can be allocated after emergency and debt priorities."
            reason = "No investment allocation exists yet."
        } else if snapshot.investmentBreakdown.highRiskRatio >= FinancialHealthWeights.highRiskConcentration {
            why = "\(highRiskPct) of your investment portfolio is exposed to higher-risk assets."
            impact = "A concentrated portfolio may experience larger fluctuations and can make financial goals more vulnerable to market volatility."
            action = "Review your asset allocation and diversification."
            reason = "\(highRiskPct) of the portfolio is in higher-risk assets."
        } else if diversification == "Low" {
            why = "Holdings are concentrated in a limited number of investment categories."
            impact = "Lower diversification can increase the effect of any single asset class on goal progress."
            action = "Review diversification across available investment types."
            reason = "Diversification is currently low."
        } else {
            why = "Investments total \(snapshot.investmentBreakdown.totalAmount.toCurrency(compact: true)) with \(highRiskPct) higher-risk exposure and \(diversification.lowercased()) diversification."
            impact = "Allocation quality can affect short- and medium-term goal stability."
            action = "Review investments periodically as goals and surplus change."
            reason = "Portfolio mix is \(diversification.lowercased()) with \(highRiskPct) higher-risk exposure."
        }

        return pack(
            parameter: .investment,
            score: score,
            overall: overall,
            metrics: metrics,
            why: why,
            impact: impact,
            action: action,
            affected: ["Portfolio volatility", "Goal stability", "Short-term financial resilience"],
            reason: reason,
            actionTitle: "Review Investments",
            destination: .investments,
            impactBoost: snapshot.investmentCount == 0 || snapshot.investmentBreakdown.highRiskRatio >= FinancialHealthWeights.highRiskConcentration
        )
    }

    private static func protection(_ snapshot: FinancialHealthSnapshot, _ score: FinancialHealthScoring.ParameterScore, overall: Double) -> FinancialHealthParameterResult {
        let dependents = snapshot.adultDependents + snapshot.childDependents
        var metrics = [
            FinancialHealthMetric(id: "health", label: "Health Insurance", value: snapshot.hasHealthInsurance ? "Available" : (score.isAssessed ? "Missing" : "Not assessed")),
            FinancialHealthMetric(id: "life", label: "Life Insurance", value: snapshot.hasLifeInsurance ? "Available" : (score.isAssessed ? "Missing" : "Not assessed")),
            FinancialHealthMetric(id: "deps", label: "Dependents", value: "\(dependents)"),
            FinancialHealthMetric(id: "cover", label: "Coverage", value: snapshot.totalProtectionCoverage > 0 ? snapshot.totalProtectionCoverage.toCurrency(compact: true) : "—")
        ]
        if snapshot.annualInsurancePremium > 0 {
            metrics.append(FinancialHealthMetric(id: "premium", label: "Annual Premium", value: snapshot.annualInsurancePremium.toCurrency(compact: true)))
        }

        let why: String
        let impact: String
        let action: String
        let reason: String
        if !score.isAssessed {
            why = "Insurance details have not been provided, so protection is not fully assessed."
            impact = "Without coverage information, family financial risk from health or income disruption cannot be estimated."
            action = "Add health and life protection details to complete this assessment."
            reason = "Protection information is needed."
        } else if let surplusBurden = snapshot.insurancePremiumToSurplus, surplusBurden > 35 {
            why = "Annual insurance premiums account for \(Int(surplusBurden.rounded()))% of your monthly surplus."
            impact = "Less money remains available for emergency savings and investment goals."
            action = "Review whether policy premiums fit comfortably into your ongoing monthly surplus."
            reason = "Insurance premium is putting pressure on your monthly surplus."
        } else if let gap = snapshot.lifeProtectionGap, gap > 0, dependents > 0 {
            why = "Recorded household life cover is \(gap.toCurrency(compact: true)) below your estimated family requirement."
            impact = "Dependents could face income replacement risk."
            action = "Review additional life protection options to cover your family's financial needs."
            reason = "Your family may have a protection gap."
        } else if snapshot.hasHealthInsurance && snapshot.hasLifeInsurance {
            why = "Core health and life protection is present\(dependents > 0 ? " and dependents are recorded" : "")."
            impact = "Existing cover can reduce the financial effect of a major health or income-related disruption."
            action = "Review coverage amounts as income and dependents change."
            reason = "Core insurance protection is present."
        } else if dependents > 0 && !snapshot.hasLifeInsurance {
            why = "You have dependents but limited life protection."
            impact = "In the event of a major health or income-related disruption, your family may face financial pressure."
            action = "Review your insurance coverage and protection needs."
            reason = "Dependents are recorded with limited life protection."
        } else if !snapshot.hasHealthInsurance {
            why = "Health insurance is not recorded, so hospital or medical costs could fall on savings or debt."
            impact = "A major medical expense may reduce emergency reserves or increase borrowing needs."
            action = "Review health coverage needs for yourself and dependents."
            reason = "Health insurance is not recorded."
        } else {
            why = "Some protection is in place, but coverage is incomplete."
            impact = "Gaps in protection can increase family financial risk during health or income disruptions."
            action = "Review insurance coverage and protection needs."
            reason = "Protection coverage is incomplete."
        }

        return pack(
            parameter: .insurance,
            score: score,
            overall: overall,
            metrics: metrics,
            why: why,
            impact: impact,
            action: action,
            affected: ["Family financial security", "Ability to absorb major unexpected costs"],
            reason: reason,
            actionTitle: "Review Protection",
            destination: .protection,
            impactBoost: dependents > 0 && (!snapshot.hasLifeInsurance || !snapshot.hasHealthInsurance)
        )
    }
}
