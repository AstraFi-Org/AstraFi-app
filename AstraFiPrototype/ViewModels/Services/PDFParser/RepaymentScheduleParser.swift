import Foundation

struct RepaymentScheduleParser: LoanStatementParser {
    func parse(text: String) -> [ParsedLoan] {
        var loans: [ParsedLoan] = []
        let lines = text.components(separatedBy: .newlines)

        var currentAmount: Double?
        var currentRate: Double?
        var currentEMI: Double?
        var currentTenure: Int?
        let currentLender: String? = nil
        let currentStartDate: Date = Date()
        let currentLoanType: AssessmentLoanEntry.LoanType = .homeLoan // Default for amortization

        // Also track amortization details (Requirement 10)
        var totalInterestPaid: Double = 0
        var payoffTimelineMonths: Int = 0

        // This is a complex parser that would usually extract a table. 
        // For the prototype, we focus on identifying if the table exists to mark it as highly accurate.
        let amountKeywords = ["sanctioned", "principal", "loan amount"]
        let rateKeywords = ["rate", "interest", "roi"]
        let emiKeywords = ["emi", "installment"]

        for (index, line) in lines.enumerated() {
            let normalizedLine = line.lowercased()

            // Find key metadata
            for key in amountKeywords {
                 if normalizedLine.contains(key) {
                      if let val = extractNumericValue(from: line) { 
                           if currentAmount == nil || val > (currentAmount ?? 0) {
                                currentAmount = val
                           }
                      }
                 }
            }
            
            for key in rateKeywords {
                 if normalizedLine.contains(key) {
                      if let val = extractNumericValue(from: line) { 
                           if val < 30 { // Usually ROI is < 30%
                                currentRate = val
                           }
                      }
                 }
            }

            for key in emiKeywords {
                 if normalizedLine.contains(key) {
                      if let val = extractNumericValue(from: line) { 
                           if currentEMI == nil {
                                currentEMI = val
                           }
                      }
                 }
            }

            // Simple table extraction logic: look for lines with mostly numbers and dates
            if normalizedLine.contains("principal") && normalizedLine.contains("interest") && normalizedLine.contains("balance") {
                 // Potentially the header of repayment schedule. 
                 // We count subsequent lines that look like numbers.
                 var tableLines = 0
                 for i in (index+1)..<min(index+150, lines.count) {
                      let nextLine = lines[i]
                      if nextLine.range(of: #"\d+"#, options: .regularExpression) != nil {
                           tableLines += 1
                      } else if tableLines > 5 {
                           break
                      }
                 }
                 if tableLines > 0 {
                      currentTenure = tableLines
                      payoffTimelineMonths = tableLines
                 }
            }
        }

        if let amount = currentAmount, amount > 0 {
            // Rough Calculation of Remaining Interest if EMI and Balance known
            if let emi = currentEMI, let _ = currentRate, let tenure = currentTenure {
                 let totalPayable = emi * Double(tenure)
                 totalInterestPaid = totalPayable - amount
            }

            let loan = ParsedLoan(
                type: currentLoanType,
                amount: amount,
                interestRate: currentRate ?? 0.0,
                emi: currentEMI ?? 0.0,
                tenure: currentTenure ?? 12,
                startDate: currentStartDate,
                outstanding: amount,
                lender: currentLender,
                totalInterestPaid: totalInterestPaid,
                remainingInterest: totalInterestPaid / 2, // Estimated
                payoffTimelineMonths: payoffTimelineMonths
            )
            loans.append(loan)
        }

        return loans
    }

    private func extractNumericValue(from text: String) -> Double? {
        let pattern = #"[₹\s]?\s?[\d,]+\.?\d*"#
        if let range = text.range(of: pattern, options: .regularExpression) {
             let valueStr = String(text[range])
                .replacingOccurrences(of: "₹", with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespaces)
             return Double(valueStr)
        }
        return nil
    }
}
