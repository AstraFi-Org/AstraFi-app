import Foundation

struct ParsedLoan: Identifiable {
    let id = UUID()
    var type: AssessmentLoanEntry.LoanType
    var amount: Double                     // Sanctioned Loan Amount
    var interestRate: Double
    var emi: Double?                       // Optional explicit EMI (nil if not in document)
    var tenure: Int                        // Total Loan Period (Months)
    var startDate: Date
    var outstanding: Double?
    var lender: String?
    var loanName: String?                  // Scheme / Product Name
    var moratoriumMonths: Int?             // Moratorium Period
    var repaymentMonths: Int?              // Repayment Period
    var insurancePremium: Double?
    var isSelected: Bool = true

    var totalCost: Double?
    var requestedAmount: Double?
    var permissibleLimit: Double?
    var actualMargin: Double?
    var interestRateType: AssessmentLoanEntry.InterestRateType = .floatingVariable
    var interestRestFrequency: AssessmentLoanEntry.InterestRestFrequency = .monthly
    var repoRate: Double?
    var markup: Double?
    var creditSpread: Double?
    var repaymentStartDate: Date?
    var maturityDate: Date?

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
        entry.sanctionedAmount = String(format: "%.0f", amount)
        entry.interestRate = String(format: "%.2f", interestRate)
        
        let totalMo = tenure
        let moraMo = moratoriumMonths ?? 0
        let repayMo = repaymentMonths ?? (totalMo > moraMo ? totalMo - moraMo : totalMo)
        
        entry.totalLoanPeriodMonths = "\(totalMo)"
        entry.moratoriumPeriodMonths = "\(moraMo)"
        entry.repaymentPeriodMonths = "\(repayMo)"
        
        entry.sanctionDate = startDate
        entry.lenderName = lender ?? ""
        entry.schemeName = loanName ?? ""
        
        if let tc = totalCost { entry.totalCost = String(format: "%.0f", tc) }
        if let req = requestedAmount { entry.requestedAmount = String(format: "%.0f", req) }
        if let perm = permissibleLimit { entry.permissibleLimit = String(format: "%.0f", perm) }
        if let marg = actualMargin { entry.actualMargin = String(format: "%.2f", marg) }
        if let out = outstanding { entry.currentOutstandingPrincipal = String(format: "%.0f", out) } else { entry.currentOutstandingPrincipal = entry.sanctionedAmount }
        if let p = insurancePremium { entry.insurancePremium = String(format: "%.0f", p) }
        
        if let e = emi, e > 0 {
            entry.emiAmount = String(format: "%.0f", e)
        }
        
        entry.interestRateType = interestRateType
        entry.interestRestFrequency = interestRestFrequency
        
        if let rr = repoRate { entry.benchmarkRate = String(format: "%.2f", rr) }
        if let mu = markup { entry.markup = String(format: "%.2f", mu) }
        if let cs = creditSpread { entry.creditSpread = String(format: "%.2f", cs) }
        
        entry.repaymentStartDate = repaymentStartDate
        entry.maturityDate = maturityDate
        
        if let data = rawLoanData {
            entry.sourceDocument = "Sanction Letter OCR"
            entry.extractionConfidence = data.confidenceScore
            entry.customData["total_payable"] = String(format: "%.0f", data.totalPayable)
            entry.customData["moratorium_interest"] = String(format: "%.0f", data.moratoriumInterest)
            entry.customData["confidence"] = String(format: "%.2f", data.confidenceScore)
        }
        
        return entry
    }
}
