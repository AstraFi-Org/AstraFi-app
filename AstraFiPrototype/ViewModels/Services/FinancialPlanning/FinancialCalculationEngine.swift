import Foundation

/// Pure deterministic mathematical engine for financial life planning calculations.
/// Conforms to Section 14 of AstraFi Architecture: Deterministic, transparent, unit-testable.
enum FinancialCalculationEngine {
    
    // MARK: - 1. Inflation Adjustment
    
    /// Calculates the future cost of a goal considering compound inflation over a time horizon.
    /// Formula: FV = PV * (1 + inflation)^years
    static func inflationAdjustedCost(
        currentCost: Double,
        annualInflationRate: Double,
        years: Double
    ) -> Double {
        guard currentCost > 0, years > 0 else { return max(0, currentCost) }
        guard annualInflationRate > -1.0 else { return currentCost }
        return currentCost * pow(1.0 + annualInflationRate, years)
    }

    // MARK: - 2. Future Value of SIP + Lump Sum
    
    /// Calculates the compounded future value of periodic monthly SIP contributions and an optional initial lump sum.
    /// Formula: FV = LumpSum * (1 + r)^n + SIP * [((1 + r)^n - 1) / r] * (1 + r)
    static func futureValue(
        monthlySIP: Double,
        annualRate: Double,
        months: Int,
        initialLumpSum: Double = 0
    ) -> Double {
        guard months > 0 else { return initialLumpSum }
        let monthlyRate = annualRate / 12.0
        
        let compoundedLumpSum: Double
        if initialLumpSum > 0 {
            compoundedLumpSum = initialLumpSum * pow(1.0 + monthlyRate, Double(months))
        } else {
            compoundedLumpSum = 0
        }
        
        guard monthlySIP > 0 else { return compoundedLumpSum }
        
        if abs(monthlyRate) < 0.000001 {
            return compoundedLumpSum + (monthlySIP * Double(months))
        }
        
        let sipCompoundingFactor = pow(1.0 + monthlyRate, Double(months))
        // Beginning of month annuity: multiplied by (1 + r)
        let sipFV = monthlySIP * ((sipCompoundingFactor - 1.0) / monthlyRate) * (1.0 + monthlyRate)
        return compoundedLumpSum + sipFV
    }

    // MARK: - 3. Required Monthly SIP
    
    /// Computes the exact monthly SIP required to achieve a target corpus over a specified horizon in months.
    static func requiredMonthlySIP(
        targetCorpus: Double,
        annualReturnRate: Double,
        months: Int,
        currentSavings: Double = 0
    ) -> Double {
        guard months > 0, targetCorpus > 0 else { return 0 }
        let monthlyRate = annualReturnRate / 12.0
        
        // Value of current savings compounded to deadline
        let compoundedSavings = currentSavings > 0 ? currentSavings * pow(1.0 + monthlyRate, Double(months)) : 0
        let remainingTarget = max(0, targetCorpus - compoundedSavings)
        guard remainingTarget > 0 else { return 0 }
        
        if abs(monthlyRate) < 0.000001 {
            return remainingTarget / Double(months)
        }
        
        let factor = pow(1.0 + monthlyRate, Double(months))
        // SIP annuity formula with contributions made at beginning of month
        let denominator = ((factor - 1.0) / monthlyRate) * (1.0 + monthlyRate)
        guard denominator > 0 else { return remainingTarget / Double(months) }
        return remainingTarget / denominator
    }

    // MARK: - 4. Time To Goal Solver (Months to Achieve)
    
    /// Solves for the number of months required to reach a target corpus given a monthly contribution and expected return rate.
    static func monthsToAchieve(
        targetCorpus: Double,
        monthlyContribution: Double,
        annualReturnRate: Double,
        currentSavings: Double = 0
    ) -> Int? {
        guard targetCorpus > currentSavings else { return 0 }
        guard monthlyContribution > 0 else { return nil }
        let monthlyRate = annualReturnRate / 12.0
        
        if abs(monthlyRate) < 0.000001 {
            let monthsNeeded = (targetCorpus - currentSavings) / monthlyContribution
            return Int(ceil(monthsNeeded))
        }
        
        // Solve: target = S*(1+r)^n + SIP * ((1+r)^n - 1)/r * (1+r)
        // Let x = (1+r)^n:
        // target = S*x + (SIP * (1+r)/r) * x - (SIP * (1+r)/r)
        // target + A = x * (S + A), where A = SIP * (1+r)/r
        let a = (monthlyContribution * (1.0 + monthlyRate)) / monthlyRate
        let numerator = targetCorpus + a
        let denominator = currentSavings + a
        guard denominator > 0, numerator > 0 else { return nil }
        let x = numerator / denominator
        guard x > 1.0 else { return 1 }
        
        let n = log(x) / log(1.0 + monthlyRate)
        guard n.isFinite, n > 0 else { return nil }
        return Int(ceil(n))
    }

    // MARK: - 5. Loan EMI & Amortization
    
    /// Computes standard reducing balance Equated Monthly Installment (EMI).
    /// Formula: EMI = [P * r * (1+r)^n] / [(1+r)^n - 1]
    static func loanEMI(
        principal: Double,
        annualInterestRate: Double,
        tenureMonths: Int
    ) -> Double {
        guard principal > 0, tenureMonths > 0 else { return 0 }
        let monthlyRate = annualInterestRate / 12.0
        guard monthlyRate > 0 else { return principal / Double(tenureMonths) }
        
        let compoundFactor = pow(1.0 + monthlyRate, Double(tenureMonths))
        let numerator = principal * monthlyRate * compoundFactor
        let denominator = compoundFactor - 1.0
        guard denominator > 0 else { return principal / Double(tenureMonths) }
        return numerator / denominator
    }

    /// Computes total interest and total repayment over the lifetime of a loan.
    static func loanAmortization(
        principal: Double,
        annualInterestRate: Double,
        tenureMonths: Int
    ) -> (totalInterest: Double, totalRepayment: Double, monthlyEMI: Double) {
        let emi = loanEMI(principal: principal, annualInterestRate: annualInterestRate, tenureMonths: tenureMonths)
        let totalRepayment = emi * Double(tenureMonths)
        let totalInterest = max(0, totalRepayment - principal)
        return (totalInterest: totalInterest, totalRepayment: totalRepayment, monthlyEMI: emi)
    }

    // MARK: - 6. Annual Step-Up SIP Calculator
    
    /// Computes accumulated corpus with an annual step-up (e.g. 10% annual increase matching salary raises).
    static func stepUpFutureValue(
        initialMonthlySIP: Double,
        annualStepUpRate: Double,
        annualReturnRate: Double,
        years: Int
    ) -> Double {
        guard years > 0, initialMonthlySIP > 0 else { return 0 }
        var currentMonthlySIP = initialMonthlySIP
        var accumulatedCorpus = 0.0
        let monthlyRate = annualReturnRate / 12.0
        
        for _ in 1...years {
            // Compound existing corpus for 12 months
            accumulatedCorpus *= pow(1.0 + monthlyRate, 12.0)
            // Add FV of this year's 12 SIP installments
            let yearSIP_FV = futureValue(monthlySIP: currentMonthlySIP, annualRate: annualReturnRate, months: 12)
            accumulatedCorpus += yearSIP_FV
            // Step-up monthly contribution for next year
            currentMonthlySIP *= (1.0 + annualStepUpRate)
        }
        
        return accumulatedCorpus
    }
}
