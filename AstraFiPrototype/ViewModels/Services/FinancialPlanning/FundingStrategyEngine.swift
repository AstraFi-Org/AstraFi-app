import Foundation

enum StrategyType: String, Codable, CaseIterable {
    case capitalPreservation = "Capital Preservation (Debt / Liquid)"
    case balancedSIP = "Balanced Wealth SIP (Hybrid)"
    case aggressiveStepUp = "Aggressive Step-Up (Equity Alpha)"
    case loanFinancing = "Partial Financing (Loan + Down Payment)"
}

struct ScenarioProjection: Equatable {
    let name: String // "Conservative", "Base", "Optimistic"
    let assumedAnnualReturn: Double
    let monthlySIPRequired: Double
    let projectedCorpusAtTarget: Double
    let monthsToAchieve: Int
    let isEarlyAchievement: Bool
    let monthsSaved: Int
}

struct GoalFundingStrategy: Identifiable, Equatable {
    var id: String { strategyType.rawValue }
    let strategyType: StrategyType
    let description: String
    let assetAllocation: String
    let recommendedFundCategories: String
    let isFeasible: Bool
    let feasibilityNote: String
    
    // 3 Core Scenarios (Section 25)
    let conservativeScenario: ScenarioProjection
    let baseScenario: ScenarioProjection
    let optimisticScenario: ScenarioProjection
}

enum FundingStrategyEngine {
    
    /// Generates feasible, constraint-checked funding strategies for a goal.
    static func generateStrategies(
        goalName: String,
        category: String,
        targetCorpus: Double,
        horizonMonths: Int,
        availableMonthlyCapacity: Double,
        currentSavings: Double = 0
    ) -> [GoalFundingStrategy] {
        let years = Double(horizonMonths) / 12.0
        var strategies: [GoalFundingStrategy] = []
        
        // 1. Capital Preservation Strategy (7% conservative return)
        let cpConservative = calculateScenario(name: "Conservative", rate: 0.06, target: targetCorpus, months: horizonMonths, savings: currentSavings)
        let cpBase = calculateScenario(name: "Base", rate: 0.075, target: targetCorpus, months: horizonMonths, savings: currentSavings)
        let cpOptimistic = calculateScenario(name: "Optimistic", rate: 0.085, target: targetCorpus, months: horizonMonths, savings: currentSavings)
        
        let cpFeasible = cpBase.monthlySIPRequired <= availableMonthlyCapacity
        let cpNote = cpFeasible ? "Fully funded within current ₹\(Int(availableMonthlyCapacity).formatted())/mo surplus." : "Requires ₹\(Int(cpBase.monthlySIPRequired - availableMonthlyCapacity).formatted())/mo more than current surplus."
        
        strategies.append(
            GoalFundingStrategy(
                strategyType: .capitalPreservation,
                description: "Focuses on capital protection, zero equity drawdown risk, and high liquidity.",
                assetAllocation: "80% Debt / Arbitrage, 20% Liquid Funds",
                recommendedFundCategories: "Arbitrage Funds, Banking & PSU Debt, Short Term Index Funds",
                isFeasible: cpFeasible,
                feasibilityNote: cpNote,
                conservativeScenario: cpConservative,
                baseScenario: cpBase,
                optimisticScenario: cpOptimistic
            )
        )
        
        // 2. Balanced Wealth SIP (10% return)
        let balConservative = calculateScenario(name: "Conservative", rate: 0.08, target: targetCorpus, months: horizonMonths, savings: currentSavings)
        let balBase = calculateScenario(name: "Base", rate: 0.10, target: targetCorpus, months: horizonMonths, savings: currentSavings)
        let balOptimistic = calculateScenario(name: "Optimistic", rate: 0.12, target: targetCorpus, months: horizonMonths, savings: currentSavings)
        
        let balFeasible = balBase.monthlySIPRequired <= availableMonthlyCapacity
        let balNote = balFeasible ? "Comfortably viable within monthly capacity." : "Slight shortfall against monthly surplus; step-up recommended."
        
        strategies.append(
            GoalFundingStrategy(
                strategyType: .balancedSIP,
                description: "Blends index equity compounding with high-grade debt stability.",
                assetAllocation: "60% Large Cap / Flexi Cap Equity, 40% Debt",
                recommendedFundCategories: "Nifty 50 Index, Flexi Cap Equity, Corporate Bond Fund",
                isFeasible: balFeasible,
                feasibilityNote: balNote,
                conservativeScenario: balConservative,
                baseScenario: balBase,
                optimisticScenario: balOptimistic
            )
        )
        
        // 3. Aggressive Step-Up Alpha (12-14% return)
        let aggConservative = calculateScenario(name: "Conservative", rate: 0.10, target: targetCorpus, months: horizonMonths, savings: currentSavings)
        let aggBase = calculateScenario(name: "Base", rate: 0.12, target: targetCorpus, months: horizonMonths, savings: currentSavings)
        let aggOptimistic = calculateScenario(name: "Optimistic", rate: 0.14, target: targetCorpus, months: horizonMonths, savings: currentSavings)
        
        let aggFeasible = aggBase.monthlySIPRequired <= (availableMonthlyCapacity * 1.2) // feasible with 10% annual salary growth
        let aggNote = aggFeasible ? "Highly viable via 10% annual savings step-up." : "Requires substantial savings expansion."
        
        strategies.append(
            GoalFundingStrategy(
                strategyType: .aggressiveStepUp,
                description: "Maximized compounding using equity index and midcap alpha with annual step-ups.",
                assetAllocation: "80% Equity (Flexi Cap + Mid Cap), 20% Multi-Asset",
                recommendedFundCategories: "Flexi Cap, Mid Cap Quality 50, Large & Mid Cap Funds",
                isFeasible: aggFeasible,
                feasibilityNote: aggNote,
                conservativeScenario: aggConservative,
                baseScenario: aggBase,
                optimisticScenario: aggOptimistic
            )
        )
        
        // 4. Financing Scenario (if Home or Vehicle and horizon >= 1 year)
        let isFinancingEligible = category.localizedCaseInsensitiveContains("Home") || category.localizedCaseInsensitiveContains("Vehicle") || category.localizedCaseInsensitiveContains("Car")
        if isFinancingEligible {
            let downPayment = targetCorpus * 0.20 // 20% down payment
            let loanAmount = targetCorpus * 0.80   // 80% loan
            let tenureMonths = category.localizedCaseInsensitiveContains("Home") ? 240 : 60
            let rate = category.localizedCaseInsensitiveContains("Home") ? 0.085 : 0.095
            let emi = FinancialCalculationEngine.loanEMI(principal: loanAmount, annualInterestRate: rate, tenureMonths: tenureMonths)
            let downPaymentSIP = FinancialCalculationEngine.requiredMonthlySIP(targetCorpus: downPayment, annualReturnRate: 0.07, months: horizonMonths, currentSavings: currentSavings)
            
            let isLoanFeasible = (emi + downPaymentSIP) <= availableMonthlyCapacity
            let loanNote = isLoanFeasible ? "Down payment SIP of ₹\(Int(downPaymentSIP).formatted())/mo fits within surplus. Future EMI: ₹\(Int(emi).formatted())/mo." : "Future EMI + down payment SIP exceeds monthly surplus."
            
            let finConservative = ScenarioProjection(name: "Conservative", assumedAnnualReturn: rate + 0.01, monthlySIPRequired: downPaymentSIP, projectedCorpusAtTarget: downPayment, monthsToAchieve: horizonMonths, isEarlyAchievement: false, monthsSaved: 0)
            let finBase = ScenarioProjection(name: "Base", assumedAnnualReturn: rate, monthlySIPRequired: downPaymentSIP, projectedCorpusAtTarget: downPayment, monthsToAchieve: horizonMonths, isEarlyAchievement: false, monthsSaved: 0)
            let finOptimistic = ScenarioProjection(name: "Optimistic", assumedAnnualReturn: rate - 0.005, monthlySIPRequired: downPaymentSIP, projectedCorpusAtTarget: downPayment, monthsToAchieve: horizonMonths, isEarlyAchievement: false, monthsSaved: 0)
            
            strategies.append(
                GoalFundingStrategy(
                    strategyType: .loanFinancing,
                    description: "Accumulate a 20% down payment (₹\(Int(downPayment).formatted())) via SIP and finance the remaining 80% (₹\(Int(loanAmount).formatted())) with an EMI of ₹\(Int(emi).formatted())/mo.",
                    assetAllocation: "100% Debt / Liquid for Down Payment",
                    recommendedFundCategories: "Short Term Debt, Ultra Short Duration Funds",
                    isFeasible: isLoanFeasible,
                    feasibilityNote: loanNote,
                    conservativeScenario: finConservative,
                    baseScenario: finBase,
                    optimisticScenario: finOptimistic
                )
            )
        }
        
        return strategies
    }
    
    private static func calculateScenario(
        name: String,
        rate: Double,
        target: Double,
        months: Int,
        savings: Double
    ) -> ScenarioProjection {
        let sip = FinancialCalculationEngine.requiredMonthlySIP(targetCorpus: target, annualReturnRate: rate, months: months, currentSavings: savings)
        let actualMonths = FinancialCalculationEngine.monthsToAchieve(targetCorpus: target, monthlyContribution: sip, annualReturnRate: rate, currentSavings: savings) ?? months
        let isEarly = actualMonths < months
        let monthsSaved = max(0, months - actualMonths)
        let fv = FinancialCalculationEngine.futureValue(monthlySIP: sip, annualRate: rate, months: actualMonths, initialLumpSum: savings)
        
        return ScenarioProjection(
            name: name,
            assumedAnnualReturn: rate,
            monthlySIPRequired: sip,
            projectedCorpusAtTarget: fv,
            monthsToAchieve: actualMonths,
            isEarlyAchievement: isEarly,
            monthsSaved: monthsSaved
        )
    }
}
