import Foundation

struct LoanStatementParserImpl: LoanStatementParser {
    func parse(text: String) -> [ParsedLoan] {
        var loans: [ParsedLoan] = []
        let lines = text.components(separatedBy: .newlines)

        let outstandingKeywords = ["principal outstanding", "balance", "total amount due", "closing balance"]
        let amountKeywords = ["sanctioned amount", "disbursed amount", "original principal"]
        let emiKeywords = ["emi", "installment"]

        var currentAmount: Double?
        var currentOutstanding: Double?
        var currentEMI: Double?
        var currentRate: Double?
        var currentLender: String?
        let currentStartDate: Date = Date()
        let currentLoanType: AssessmentLoanEntry.LoanType = .personalLoan

        for line in lines {
            let normalizedLine = line.lowercased()

            for key in outstandingKeywords {
                if normalizedLine.contains(key) {
                    if let value = extractNumericValue(from: line) {
                        currentOutstanding = value
                    }
                }
            }

            for key in amountKeywords {
                 if normalizedLine.contains(key) {
                    if let value = extractNumericValue(from: line) {
                        currentAmount = value
                    }
                }
            }

            for key in emiKeywords {
                 if normalizedLine.contains(key) {
                    if let value = extractNumericValue(from: line) {
                        currentEMI = value
                    }
                }
            }

            if normalizedLine.contains("interest") || normalizedLine.contains("rate") {
                if let value = extractNumericValue(from: line) {
                    if value < 30 { currentRate = value }
                }
            }

            if normalizedLine.contains("bank") || normalizedLine.contains("lender") {
                let cmps = line.components(separatedBy: ":")
                if cmps.count > 1 {
                    currentLender = cmps[1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }

        if let amount = currentAmount, amount > 0 {
            let loan = ParsedLoan(
                type: currentLoanType,
                amount: amount,
                interestRate: currentRate ?? 0.0,
                emi: currentEMI ?? 0.0,
                tenure: 12, // Generic fallback if not parsed
                startDate: currentStartDate,
                outstanding: currentOutstanding,
                lender: currentLender
            )
            loans.append(loan)
        } else if let out = currentOutstanding, out > 0 {
             // Fallback if original amount not detected: Outstanding as principal
             let loan = ParsedLoan(
                type: currentLoanType,
                amount: out,
                interestRate: currentRate ?? 0.0,
                emi: currentEMI ?? 0.0,
                tenure: 12,
                startDate: currentStartDate,
                outstanding: out,
                lender: currentLender
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
