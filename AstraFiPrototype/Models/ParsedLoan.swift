import Foundation

struct ParsedLoan: Identifiable {
    let id = UUID()
    var type: AssessmentLoanEntry.LoanType
    var amount: Double
    var interestRate: Double
    var emi: Double
    var tenure: Int // In months
    var startDate: Date
    var outstanding: Double?
    var lender: String?
    var loanName: String?
    var moratoriumMonths: Int?
    var insurancePremium: Double?
    var isSelected: Bool = true

    // Advanced: Repayment breakdown if detected
    var totalInterestPaid: Double?
    var remainingInterest: Double?
    var payoffTimelineMonths: Int?
    
    // Extraction insights
    var confidenceScore: Double = 0.0
    var rawLoanData: LoanData?

    func toAssessmentEntry() -> AssessmentLoanEntry {
        var entry = AssessmentLoanEntry()
        entry.type = type
        entry.amount = String(format: "%.0f", amount)
        entry.interestRate = String(format: "%.2f", interestRate)
        
        // Convert months to years
        let years = Double(tenure) / 12.0
        entry.tenure = String(format: "%.0f", years)
        
        entry.loanName = loanName ?? ""
        if let m = moratoriumMonths {
            entry.moratorium = "\(m)"
        }
        if let p = insurancePremium {
            entry.insurancePremium = String(format: "%.0f", p)
        }
        
        // Custom: pass the detailed breakdown if we have it
        if let data = rawLoanData {
             entry.customData["total_payable"] = String(format: "%.0f", data.totalPayable)
             entry.customData["moratorium_interest"] = String(format: "%.0f", data.moratoriumInterest)
             entry.customData["confidence"] = String(format: "%.2f", data.confidenceScore)
        }
        
        return entry
    }
}
