import Foundation

@MainActor
enum FinancialHealthCalculations {
    static func parseNumber(_ value: String?) -> Double {
        guard let value else { return 0 }
        let cleaned = value
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "₹", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return max(0, Double(cleaned) ?? 0)
    }

    static func clamp(_ value: Double, _ lower: Double = 0, _ upper: Double = 1) -> Double {
        min(upper, max(lower, value))
    }

    static func estimateEMI(for entry: AssessmentLoanEntry) -> Double {
        let explicitEMI = parseNumber(entry.emiAmount)
        if explicitEMI > 0 { return explicitEMI }

        let principal = parseNumber(entry.sanctionedAmount.isEmpty ? entry.amount : entry.sanctionedAmount)
        let annualRate = parseNumber(entry.interestRate) / 100
        let repayMonthsRaw = parseNumber(entry.repaymentPeriodMonths)
        let totalMonthsRaw = parseNumber(entry.totalLoanPeriodMonths)
        let moraMonthsRaw = parseNumber(entry.moratoriumPeriodMonths)

        let months: Int
        if repayMonthsRaw > 0 {
            months = repayMonthsRaw.safeInt
        } else if totalMonthsRaw > 0 {
            months = max(1, (totalMonthsRaw - moraMonthsRaw).safeInt)
        } else {
            months = max(1, parseNumber(entry.tenure).safeInt)
        }

        guard principal > 0 else { return 0 }
        if annualRate <= 0 { return principal / Double(months) }

        let monthlyRate = annualRate / 12
        let growth = pow(1 + monthlyRate, Double(months))
        guard (growth - 1) != 0 else { return principal / Double(months) }
        let emi = (principal * monthlyRate * growth) / (growth - 1)
        return emi.isFinite ? max(0, emi) : 0
    }

    static func computeDebtToIncomeRatio(
        profile: AstraUserProfile?,
        data: CompleteAssessmentData?,
        grossIncome: Double
    ) -> Double {
        guard grossIncome > 0 else { return 0 }
        return clamp(totalMonthlyEMI(profile: profile, data: data) / grossIncome)
    }

    static func totalMonthlyEMI(profile: AstraUserProfile?, data: CompleteAssessmentData?) -> Double {
        if let data {
            return data.loanEntries.reduce(0) { $0 + estimateEMI(for: $1) }
        }
        if let profile {
            return profile.loans.reduce(0) { $0 + max(0, $1.calculatedEMI) }
        }
        return 0
    }

    static func totalMonthlyInsurancePremium(profile: AstraUserProfile?, data: CompleteAssessmentData?) -> Double {
        if let data {
            return data.insuranceEntries.reduce(0) { $0 + parseNumber($1.annualPremium) / 12 }
        }
        return profile?.insurances.reduce(0) { $0 + max(0, $1.annualPremium) / 12 } ?? 0
    }

    static func snapshot(from insights: FinancialAssessmentInsights, profile: AstraUserProfile?, data: CompleteAssessmentData?) -> FinancialHealthSnapshot {
        let income = insights.monthlyIncome
        let expenses = insights.monthlyExpenses
        // Insurance premiums are obligations, not investments: deduct them before
        // presenting a safe monthly surplus for goals and investment planning.
        let surplus = income - expenses - totalMonthlyInsurancePremium(profile: profile, data: data)
        let expenseRatio = income > 0 ? expenses / income : 0
        let savingsRate = income > 0 ? surplus / income : 0
        let emiFromLoans = totalMonthlyEMI(profile: profile, data: data)
        let emi = emiFromLoans > 0
            ? emiFromLoans
            : max(0, insights.debtToIncomeRatio * insights.grossMonthlyIncome)
        let dti = insights.grossMonthlyIncome > 0 ? emi / insights.grossMonthlyIncome : insights.debtToIncomeRatio
        let emiToSurplus = surplus > 0 ? emi / surplus : (emi > 0 ? Double.greatestFiniteMagnitude : 0)

        let outstanding = outstandingDebt(profile: profile, data: data)
        let highInterest = highInterestDebt(profile: profile, data: data)
        let remainingInterest = remainingInterestEstimate(profile: profile, data: data)
        let debtFree = debtFreeDate(profile: profile, data: data)

        let (essential, isEstimate) = essentialExpenses(profile: profile, fallbackExpenses: expenses)
        let includeEMI = shouldAddEMIToEmergencyNeed(profile: profile, essential: essential, isEstimate: isEstimate)
        let monthlyNeed = max(1, essential + (includeEMI ? emi : 0))
        let emergencyAssessed = emergencyFundIsAssessed(profile: profile, data: data)
        let target = FinancialHealthWeights.emergencyFundMonths * monthlyNeed
        let coverageMonths = insights.emergencyFundAmount / monthlyNeed
        let gap = max(0, target - insights.emergencyFundAmount)

        let contribution = monthlyInvestmentContribution(profile: profile, data: data)
        let categories = uniqueInvestmentCategories(profile: profile, data: data)
        let (goalTarget, goalCurrent) = goalTotals(profile: profile)
        let coverage = protectionCoverage(profile: profile, data: data)
        let childDeps = profile?.basicDetails.childDependents ?? 0
        let stability = incomeStabilityScore(from: profile)

        let vitalsAssessed = income > 0
        let insuranceAssessed = insuranceIsAssessed(profile: profile, data: data)
        let investmentAssessed = true

        return FinancialHealthSnapshot(
            monthlyIncome: income,
            grossMonthlyIncome: insights.grossMonthlyIncome,
            monthlyExpenses: expenses,
            monthlySurplus: surplus,
            savingsRate: savingsRate,
            expenseRatio: expenseRatio,
            incomeStability: stability,
            vitalsAssessed: vitalsAssessed,
            hasFixedIncome: insights.hasFixedIncome,
            emergencyFundAmount: insights.emergencyFundAmount,
            emergencyFundAssessed: emergencyAssessed,
            essentialMonthlyExpenses: essential,
            emergencyMonthlyNeed: monthlyNeed,
            emergencyTarget: target,
            emergencyCoverageMonths: coverageMonths,
            emergencyGap: gap,
            emergencyTargetIsEstimate: isEstimate,
            loanCount: insights.loanCount,
            totalMonthlyEMI: emi,
            outstandingDebt: outstanding,
            debtToIncomeRatio: max(0, dti),
            emiToSurplusRatio: emiToSurplus.isFinite ? max(0, emiToSurplus) : 10,
            hasHighRiskDebt: insights.hasHighRiskDebt,
            highInterestDebtAmount: highInterest,
            remainingInterestEstimate: remainingInterest,
            debtFreeDate: debtFree,
            investmentBreakdown: insights.investmentBreakdown,
            investmentCount: insights.investmentCount,
            uniqueInvestmentCategories: categories,
            monthlyInvestmentContribution: contribution,
            investmentAssessed: investmentAssessed,
            goalTargetTotal: goalTarget,
            goalCurrentTotal: goalCurrent,
            insuranceCount: insights.insuranceCount,
            hasHealthInsurance: insights.hasHealthInsurance,
            hasLifeInsurance: insights.hasLifeInsurance,
            adultDependents: insights.adultDependents,
            childDependents: childDeps,
            totalProtectionCoverage: coverage,
            insuranceAssessed: insuranceAssessed
        )
    }

    static func outstandingDebt(profile: AstraUserProfile?, data: CompleteAssessmentData?) -> Double {
        if let data {
            return data.loanEntries.reduce(0) { sum, entry in
                let outstanding = parseNumber(entry.currentOutstandingPrincipal)
                if outstanding > 0 { return sum + outstanding }
                return sum + parseNumber(entry.sanctionedAmount.isEmpty ? entry.amount : entry.sanctionedAmount)
            }
        }
        return profile?.loans.reduce(0) { $0 + $1.remainingPrincipal } ?? 0
    }

    static func highInterestDebt(profile: AstraUserProfile?, data: CompleteAssessmentData?) -> Double {
        if let data {
            return data.loanEntries.reduce(0) { sum, entry in
                let rate = parseNumber(entry.interestRate)
                let isHigh = entry.type == .creditCard || entry.type == .personalLoan || rate >= 15
                guard isHigh else { return sum }
                let outstanding = parseNumber(entry.currentOutstandingPrincipal)
                let amount = outstanding > 0 ? outstanding : parseNumber(entry.amount)
                return sum + amount
            }
        }
        return profile?.loans.reduce(0) { sum, loan in
            let isHigh = loan.loanType == .creditCard || loan.loanType == .personalLoan || loan.interestRate >= 15
            return isHigh ? sum + loan.remainingPrincipal : sum
        } ?? 0
    }

    static func remainingInterestEstimate(profile: AstraUserProfile?, data: CompleteAssessmentData?) -> Double? {
        if let profile, !profile.loans.isEmpty {
            let total = profile.loans.reduce(0.0) { sum, loan in
                let remainingMonths = max(0, loan.loanTenureMonths - loan.installmentsPaid)
                guard remainingMonths > 0 else { return sum }
                let remainingPayable = loan.calculatedEMI * Double(remainingMonths)
                return sum + max(0, remainingPayable - loan.remainingPrincipal)
            }
            return total > 0 ? total : nil
        }
        if let data, !data.loanEntries.isEmpty {
            var total = 0.0
            var hadData = false
            for entry in data.loanEntries {
                let emi = estimateEMI(for: entry)
                let remaining = parseNumber(entry.emisRemaining)
                let outstanding = parseNumber(entry.currentOutstandingPrincipal)
                if remaining > 0, emi > 0 {
                    hadData = true
                    total += max(0, emi * remaining - outstanding)
                }
            }
            return hadData ? total : nil
        }
        return nil
    }

    static func debtFreeDate(profile: AstraUserProfile?, data: CompleteAssessmentData?) -> Date? {
        if let profile {
            let dates = profile.loans.compactMap { loan -> Date? in
                Calendar.current.date(byAdding: .month, value: max(0, loan.loanTenureMonths - loan.installmentsPaid), to: Date())
            }
            return dates.max()
        }
        if let data {
            let dates = data.loanEntries.compactMap(\.maturityDate)
            return dates.max()
        }
        return nil
    }

    static func monthlyInvestmentContribution(profile: AstraUserProfile?, data: CompleteAssessmentData?) -> Double {
        if let data {
            return data.investmentEntries.reduce(0) { sum, entry in
                guard entry.mode == .sip else { return sum }
                return sum + parseNumber(entry.amount)
            }
        }
        return profile?.investments.reduce(0) { sum, inv in
            inv.mode == .sip ? sum + max(0, inv.investmentAmount) : sum
        } ?? 0
    }

    static func uniqueInvestmentCategories(profile: AstraUserProfile?, data: CompleteAssessmentData?) -> Int {
        if let data {
            return Set(data.investmentEntries.map(\.type)).count
        }
        return Set(profile?.investments.map(\.investmentType) ?? []).count
    }

    static func protectionCoverage(profile: AstraUserProfile?, data: CompleteAssessmentData?) -> Double {
        if let data {
            return data.insuranceEntries.reduce(0) { $0 + parseNumber($1.coverAmount) }
        }
        return profile?.insurances.reduce(0) { $0 + $1.sumAssured } ?? 0
    }

    static func goalTotals(profile: AstraUserProfile?) -> (Double, Double) {
        guard let profile, !profile.goals.isEmpty else { return (0, 0) }
        let target = profile.goals.reduce(0) { $0 + $1.targetAmount }
        let current = profile.goals.reduce(0) { $0 + $1.currentAmount }
        return (target, current)
    }

    static func incomeStabilityScore(from profile: AstraUserProfile?) -> Double? {
        guard let snapshots = profile?.monthlyCashflowSnapshots else { return nil }
        let incomes = snapshots.values.map(\.totalIncome).filter { $0 > 0 }
        guard incomes.count >= 3 else { return nil }
        let mean = incomes.reduce(0, +) / Double(incomes.count)
        guard mean > 0 else { return nil }
        let variance = incomes.reduce(0) { $0 + pow($1 - mean, 2) } / Double(incomes.count)
        let cv = sqrt(variance) / mean
        return clamp(1 - (cv / 0.40))
    }

    static func essentialExpenses(profile: AstraUserProfile?, fallbackExpenses: Double) -> (Double, Bool) {
        if let cf = profile?.cashflowData, cf.total > 0 {
            if !cf.expenseSources.isEmpty {
                return (cf.totalExpenses, false)
            }
            let essentials = cf.rent + cf.groceries + cf.utilities + cf.transport
            if essentials > 0 { return (essentials, false) }
            return (cf.total, false)
        }
        if fallbackExpenses > 0 { return (fallbackExpenses, true) }
        return (0, true)
    }

    static func shouldAddEMIToEmergencyNeed(profile: AstraUserProfile?, essential: Double, isEstimate: Bool) -> Bool {
        if let cf = profile?.cashflowData, cf.rent > 0, !isEstimate { return false }
        return true
    }

    static func emergencyFundIsAssessed(profile: AstraUserProfile?, data: CompleteAssessmentData?) -> Bool {
        if profile == nil && data == nil { return true }
        if let data {
            return !data.emergencyFundAmount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return (profile?.basicDetails.emergencyFundAmount ?? 0) > 0
            || profile?.financialHealthReport != nil
            || !(profile?.monthlyHealthAssessments.isEmpty ?? true)
    }

    static func insuranceIsAssessed(profile: AstraUserProfile?, data: CompleteAssessmentData?) -> Bool {
        if profile == nil && data == nil { return true }
        if let data {
            return data.hasCompletedInsuranceStep || data.isInsured || !data.insuranceEntries.isEmpty
        }
        if let profile {
            return !profile.insurances.isEmpty
                || profile.financialHealthReport != nil
                || !profile.monthlyHealthAssessments.isEmpty
        }
        return false
    }

    static func diversificationLabel(count: Int, categories: Int) -> String {
        if count == 0 { return "None" }
        if count >= 3 && categories >= 2 { return "Good" }
        if count >= 2 || categories >= 2 { return "Moderate" }
        return "Low"
    }
}
