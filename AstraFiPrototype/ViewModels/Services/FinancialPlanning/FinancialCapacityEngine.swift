import Foundation

/// Analyzes real financial capacity of a user profile.
/// Conforms to Section 15 of AstraFi Architecture: Income - Essential Expenses - Debt - Commitments = Available Capacity.
struct FinancialCapacityBreakdown: Equatable {
    let monthlyIncome: Double
    let monthlyExpenses: Double
    let existingDebtEMIs: Double
    let insuranceCommitments: Double
    let emergencyFundRequirement: Double
    let currentEmergencyReserve: Double
    let emergencyFundShortfall: Double
    
    /// Unconstrained cash surplus: Income - Expenses - EMIs
    let grossMonthlySurplus: Double
    
    /// Net safe planning capacity available for goal investing (reserving a safety buffer if emergency fund is incomplete)
    let availableMonthlyPlanningCapacity: Double
    
    /// Annualized planning capacity
    var annualPlanningCapacity: Double {
        availableMonthlyPlanningCapacity * 12.0
    }
    
    /// Debt-to-income ratio (DTI %)
    var debtToIncomeRatio: Double {
        guard monthlyIncome > 0 else { return 0 }
        return (existingDebtEMIs / monthlyIncome) * 100.0
    }
    
    /// Explainable capacity health notes
    let capacityInsights: [String]
}

enum FinancialCapacityEngine {
    
    /// Analyzes the true financial capacity from verified user profile data.
    static func evaluateCapacity(profile: AstraUserProfile?) -> FinancialCapacityBreakdown {
        guard let profile else {
            return FinancialCapacityBreakdown(
                monthlyIncome: 0,
                monthlyExpenses: 0,
                existingDebtEMIs: 0,
                insuranceCommitments: 0,
                emergencyFundRequirement: 0,
                currentEmergencyReserve: 0,
                emergencyFundShortfall: 0,
                grossMonthlySurplus: 0,
                availableMonthlyPlanningCapacity: 0,
                capacityInsights: ["Please complete your financial profile to calculate verified capacity."]
            )
        }
        
        let basic = profile.basicDetails
        let income = basic.monthlyIncomeAfterTax > 0 ? basic.monthlyIncomeAfterTax : max(0, basic.monthlyIncome)
        let expenses = max(0, basic.monthlyExpenses)
        let debtEMIs = profile.loans.reduce(0.0) { $0 + max(0, $1.calculatedEMI) }
        
        // Insurance annual premiums converted to monthly commitment
        let insuranceMonthly = profile.insurances.reduce(0.0) { $0 + (max(0, $1.annualPremium) / 12.0) }
        
        let emergencyReserve = max(0, basic.emergencyFundAmount)
        // 6 months of mandatory living costs
        let mandatoryCostPerMonth = expenses + debtEMIs
        let targetEmergencyFund = mandatoryCostPerMonth * 6.0
        let emergencyShortfall = max(0, targetEmergencyFund - emergencyReserve)
        
        let grossSurplus = max(0, income - expenses - debtEMIs - insuranceMonthly)
        
        // If emergency fund has a critical shortfall, reserve 15% of surplus towards emergency building
        let emergencyAllocation = emergencyShortfall > 0 ? min(grossSurplus * 0.15, emergencyShortfall / 12.0) : 0
        let safePlanningCapacity = max(0, grossSurplus - emergencyAllocation)
        
        var insights: [String] = []
        if grossSurplus > 0 {
            insights.append("Verified monthly surplus is ₹\(Int(grossSurplus).formatted()) after essential expenses and debt obligations.")
        } else {
            insights.append("Monthly living expenses and existing EMIs currently consume all monthly income.")
        }
        
        let dti = income > 0 ? (debtEMIs / income) * 100.0 : 0
        if dti > 40.0 {
            insights.append("Debt-to-Income ratio is high at \(Int(dti))%. Debt reduction should be prioritized before large capital goals.")
        } else if dti > 0 {
            insights.append("Debt-to-Income ratio is healthy at \(Int(dti))%.")
        }
        
        if emergencyShortfall > 0 {
            insights.append("Emergency reserve is below the 6-month target of ₹\(Int(targetEmergencyFund).formatted()). A ₹\(Int(emergencyAllocation).formatted())/mo allocation is recommended alongside goals.")
        } else if emergencyReserve > 0 {
            insights.append("Emergency fund of ₹\(Int(emergencyReserve).formatted()) is fully resilient.")
        }
        
        return FinancialCapacityBreakdown(
            monthlyIncome: income,
            monthlyExpenses: expenses,
            existingDebtEMIs: debtEMIs,
            insuranceCommitments: insuranceMonthly,
            emergencyFundRequirement: targetEmergencyFund,
            currentEmergencyReserve: emergencyReserve,
            emergencyFundShortfall: emergencyShortfall,
            grossMonthlySurplus: grossSurplus,
            availableMonthlyPlanningCapacity: safePlanningCapacity,
            capacityInsights: insights
        )
    }
}
