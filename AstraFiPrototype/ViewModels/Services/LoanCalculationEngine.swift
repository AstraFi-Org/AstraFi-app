import Foundation

struct LoanCalculationEngine {
    
    /// Calculates EMI using the formula: EMI = P × r × (1+r)^n / ((1+r)^n - 1)
    /// - Parameters:
    ///   - principal: Loan amount (P)
    ///   - annualRate: Annual interest rate as a percentage (e.g., 11.15 for 11.15%)
    ///   - months: Loan tenure in months (n)
    /// - Returns: Calculated monthly EMI
    static func calculateEMI(principal: Double, annualRate: Double, months: Int) -> Double {
        guard months > 0 && annualRate > 0 else { return 0 }
        
        let monthlyRate = (annualRate / 100.0) / 12.0
        let r = monthlyRate
        let n = Double(months)
        
        let numerator = principal * r * pow(1 + r, n)
        let denominator = pow(1 + r, n) - 1
        
        return numerator / denominator
    }
    
    /// Calculates interest accrued during the moratorium period.
    /// - Parameters:
    ///   - principal: Initial loan amount
    ///   - annualRate: Annual interest rate percentage
    ///   - moratoriumMonths: Duration of moratorium in months
    /// - Returns: Total interest accrued (assuming monthly compounding as standard in banking)
    static func calculateMoratoriumInterest(principal: Double, annualRate: Double, moratoriumMonths: Int) -> Double {
        guard moratoriumMonths > 0 && annualRate > 0 else { return 0 }
        
        let monthlyRate = (annualRate / 100.0) / 12.0
        
        // Final Amount = P * (1 + r)^n
        let finalAmount = principal * pow(1 + monthlyRate, Double(moratoriumMonths))
        return finalAmount - principal
    }
    
    struct AmortizationRow {
        let month: Int
        let openingBalance: Double
        let interest: Double
        let principalPaid: Double
        let closingBalance: Double
    }
    
    /// Generates a monthly breakdown of principal vs interest split.
    static func generateAmortizationSchedule(principal: Double, annualRate: Double, months: Int, emi: Double) -> [AmortizationRow] {
        var schedule: [AmortizationRow] = []
        var balance = principal
        let monthlyRate = (annualRate / 100.0) / 12.0
        
        for month in 1...months {
            let interest = balance * monthlyRate
            let principalPaid = emi - interest
            let closingBalance = max(0, balance - principalPaid)
            
            schedule.append(AmortizationRow(
                month: month,
                openingBalance: balance,
                interest: interest,
                principalPaid: principalPaid,
                closingBalance: closingBalance
            ))
            
            balance = closingBalance
            if balance <= 0 { break }
        }
        
        return schedule
    }
}
