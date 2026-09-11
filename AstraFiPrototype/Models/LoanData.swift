import Foundation

struct LoanData: Codable {
    var loanType: String = ""
    var scheme: String = ""
    var productName: String = ""
    var facilityType: String = ""
    var lender: String = ""
    var purpose: String = ""
    
    var principal: Double = 0.0           // Sanctioned Amount / Loan Amount
    var totalCost: Double = 0.0           // Total Project / Course Cost
    var requestedAmount: Double = 0.0
    var permissibleLimit: Double = 0.0
    var actualMargin: Double = 0.0        // Margin percentage e.g. 46.26%
    var insurance: Double = 0.0
    var currentOutstanding: Double = 0.0
    
    var interestRate: Double = 0.0
    var repoRate: Double = 0.0
    var markup: Double = 0.0
    var creditSpread: Double = 0.0
    var interestRateType: String = "Floating / Variable"
    var interestRestFrequency: String = "Monthly"
    
    var totalLoanPeriodMonths: Int = 0    // e.g. 96 months Total Period
    var moratorium: Int = 0               // e.g. 55 months Moratorium
    var emiMonths: Int = 0                // e.g. 41 months Repayment Period
    var tenure: Int = 0                   // Total period compatibility
    
    var emi: Double? = nil                // Optional EMI (nil if not explicitly printed)
    var emiDueDateDay: Int? = nil
    
    // Calculated fields
    var calculatedEMI: Double = 0.0
    var totalInterest: Double = 0.0
    var moratoriumInterest: Double = 0.0
    var totalPayable: Double = 0.0
    
    // Dates
    var sanctionDate: Date?
    var repaymentStartDate: Date?
    var maturityDate: Date?
    
    // Metadata
    var confidenceScore: Double = 0.0
    
    func ToJSONString() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(self) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
