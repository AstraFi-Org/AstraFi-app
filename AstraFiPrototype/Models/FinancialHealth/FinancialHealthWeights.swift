import Foundation

enum FinancialHealthWeights {
    static let financialVitals = 0.25
    static let debtHealth = 0.20
    static let emergencyReadiness = 0.20
    static let investmentHealth = 0.20
    static let riskProtection = 0.15

    static let savingsRateTarget = 0.30
    static let emergencyFundMonths = 6.0
    static let healthyDebtToIncome = 0.30
    static let stressedDebtToIncome = 0.45
    static let highRiskConcentration = 0.80
    static let recommendedLifeCoverMultiple = 10.0

    static func weight(for parameter: AssessmentParameter) -> Double {
        switch parameter {
        case .vitals: return financialVitals
        case .liabilities: return debtHealth
        case .emergencyFund: return emergencyReadiness
        case .investment: return investmentHealth
        case .insurance: return riskProtection
        }
    }
}

enum FinancialHealthStatusBand {
    static func overallTitle(for score: Int) -> String {
        switch score {
        case 90...100: return "Excellent"
        case 75..<90: return "Good"
        case 60..<75: return "Fair"
        case 40..<60: return "Needs Attention"
        default: return "Critical"
        }
    }

    static func parameterTitle(for scoreOutOf10: Double) -> String {
        overallTitle(for: Int((scoreOutOf10 * 10).rounded()))
    }
}
