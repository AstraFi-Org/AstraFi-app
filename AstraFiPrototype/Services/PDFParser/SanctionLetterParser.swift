import Foundation

struct SanctionLetterParser: LoanStatementParser {
    func parse(text: String) -> [ParsedLoan] {
        var loans: [ParsedLoan] = []
        let lines = text.components(separatedBy: .newlines)

        // Normalization keywords (Requirement 5)
        let amountKeywords = ["loan amount", "sanctioned amount", "disbursed amount", "principal amount"]
        let rateKeywords = ["interest rate", "roi", "rate of interest", "p.a."]
        let emiKeywords = ["emi", "installment amount", "monthly installment"]
        let tenureKeywords = ["tenure", "loan duration", "period", "months"]
        let lenderKeywords = ["bank", "lender", "financier", "hfc"]
        let dateKeywords = ["disbursement date", "sanction date", "date of sanction"]

        var currentAmount: Double?
        var currentRate: Double?
        var currentEMI: Double?
        var currentTenure: Int?
        var currentLender: String?
        var currentStartDate: Date = Date()
        var currentLoanType: AssessmentLoanEntry.LoanType = .personalLoan // Default

        for line in lines {
            let normalizedLine = line.lowercased()
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty { continue }

            // Detect loan type based on keywords
            if (normalizedLine.contains("home") || normalizedLine.contains("housing") || normalizedLine.contains("mortgage") || normalizedLine.contains("property")) && !normalizedLine.contains("insurance") {
                currentLoanType = .homeLoan
            } else if normalizedLine.contains("education") || normalizedLine.contains("study") || normalizedLine.contains("student") {
                currentLoanType = .educationLoan
            } else if normalizedLine.contains("car") || normalizedLine.contains("vehicle") || normalizedLine.contains("auto") {
                currentLoanType = .carLoan
            } else if normalizedLine.contains("business") || normalizedLine.contains("commercial") || normalizedLine.contains("enterprise") {
                currentLoanType = .businessLoan
            } else if normalizedLine.contains("personal") || normalizedLine.contains("unsecured") || normalizedLine.contains("express") {
                currentLoanType = .personalLoan
            }

            // Extract numeric fields using keywords
            for key in amountKeywords {
                if normalizedLine.contains(key) {
                    if let value = extractNumericValue(from: line) {
                        if currentAmount == nil || value > (currentAmount ?? 0) {
                            currentAmount = value
                        }
                    }
                }
            }

            if currentAmount == nil && (normalizedLine.contains("limit") || normalizedLine.contains("sanction")) {
                 if let value = extractNumericValue(from: line) {
                     currentAmount = value
                 }
            }

            for key in rateKeywords {
                if normalizedLine.contains(key) {
                    if let value = extractNumericValue(from: line) {
                        currentRate = value
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

            for key in tenureKeywords {
                 if normalizedLine.contains(key) {
                    if let value = extractNumericValue(from: line) {
                        if value > 0 && value < 400 { // Max 30-40 years or months
                             currentTenure = Int(value)
                        }
                    }
                }
            }

            for key in lenderKeywords {
                 if normalizedLine.contains(key) {
                    let cmps = line.components(separatedBy: ":")
                    if cmps.count > 1 {
                        currentLender = cmps[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    } else if currentLender == nil {
                        if line.count < 40 {
                            currentLender = trimmedLine
                        }
                    }
                }
            }

            for key in dateKeywords {
                 if normalizedLine.contains(key) {
                    if let dateStr = extractDateString(from: line) {
                         currentStartDate = parseDate(dateStr) ?? currentStartDate
                    }
                }
            }
        }

        // Final check
        if let amount = currentAmount, amount > 0 {
            let loan = ParsedLoan(
                type: currentLoanType,
                amount: amount,
                interestRate: currentRate ?? 0.0,
                emi: currentEMI ?? 0.0,
                tenure: currentTenure ?? 12,
                startDate: currentStartDate,
                outstanding: amount, // For sanction letter, outstanding is usually full amount or undisbursed
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

    private func extractDateString(from text: String) -> String? {
        let patterns = [#"\d{1,2}[/-]\d{1,2}[/-]\d{2,4}"#, #"\d{1,2}-[A-Za-z]{3}-\d{4}"#]
        for pattern in patterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                return String(text[range])
            }
        }
        return nil
    }

    private func parseDate(_ str: String) -> Date? {
        let formats = ["dd/MM/yyyy", "dd-MM-yyyy", "dd-MMM-yyyy", "dd MMM yyyy", "dd/MM/yy"]
        let formatter = DateFormatter()
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: str) {
                return date
            }
        }
        return nil
    }
}
