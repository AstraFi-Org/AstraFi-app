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
    var isSelected: Bool = true

    // Advanced: Repayment breakdown if detected
    var totalInterestPaid: Double?
    var remainingInterest: Double?
    var payoffTimelineMonths: Int?

    func toAssessmentEntry() -> AssessmentLoanEntry {
        var entry = AssessmentLoanEntry()
        entry.type = type
        entry.bank = lender ?? ""
        entry.amount = String(format: "%.0f", amount)
        entry.interestRate = String(format: "%.2f", interestRate)
        entry.emiAmount = String(format: "%.0f", emi)
        
        // Convert months to years
        let years = Double(tenure) / 12.0
        entry.timePeriod = String(format: "%.0f", years)
        
        entry.startDate = startDate
        
        // If we have outstanding balance, we can estimate installments paid
        if let out = outstanding, amount > 0 {
            // Very rough estimation if not provided in PDF
            let paidRatio = 1.0 - (out / amount)
            let paidMonths = Int(Double(tenure) * paidRatio)
            entry.installmentsPaid = "\(paidMonths)"
        }
        
        return entry
    }
}
