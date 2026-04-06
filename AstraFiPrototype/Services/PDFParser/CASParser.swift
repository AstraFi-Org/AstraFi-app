import Foundation

struct CASParser: StatementParser {
    func parse(text: String) -> [ParsedInvestment] {
        var investments: [ParsedInvestment] = []

        // Keywords for normalization (Requirement 4)
        let amountKeywords = ["amount invested", "cost value", "purchase value", "invested amount"]
        let fundKeywords = ["scheme name", "fund name", "scheme", "fund"]
        let unitKeywords = ["units", "quantity", "balance units"]

        // Basic line-by-line parsing strategy for simplicity
        let lines = text.components(separatedBy: .newlines)

        var currentFund: String?
        var currentAmount: Double?
        var currentUnits: Double?
        var currentMode: String = "Lumpsum"
        var currentDates: [Date] = []

        for line in lines {
            let normalizedLine = line.lowercased()
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedLine.isEmpty || trimmedLine.count < 5 { continue }

            // 1. Try to find fund name using strict keywords
            var foundFundInLine = false
            for keyword in fundKeywords {
                if normalizedLine.contains(keyword) {
                    let components = line.components(separatedBy: ":")
                    if components.count > 1 {
                        currentFund = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    } else {
                        currentFund = line.replacingOccurrences(of: keyword, with: "", options: .caseInsensitive)
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    foundFundInLine = true
                    break
                }
            }

            // 2. Extract numeric values (Amount/Units)
            let amountInLine = extractNumericValue(from: line)
            
            // 3. Strict Check: If we found an amount AND the line contains "Fund", "Equity", "Direct", or "Growth"
            if !foundFundInLine && amountInLine != nil && (normalizedLine.contains("fund") || normalizedLine.contains("equity") || normalizedLine.contains("direct") || normalizedLine.contains("growth")) {
                 // Likely a fund holding line.
                 // Extract fund name by removing the number
                 if let range = line.range(of: #"\d"# , options: .regularExpression) {
                      let potentialName = String(line[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                      if potentialName.count > 5 {
                          currentFund = potentialName
                          foundFundInLine = true
                      }
                 }
            }

            // Only proceed if we have a fund name candidate
            if !foundFundInLine && currentFund == nil { continue }

            // Extract units/quantity
            for keyword in unitKeywords {
                if normalizedLine.contains(keyword) {
                    if let value = extractNumericValue(from: line) {
                        currentUnits = value
                    }
                }
            }

            // Extract amount invested
            for keyword in amountKeywords {
                if normalizedLine.contains(keyword) {
                    if let value = extractNumericValue(from: line) {
                        currentAmount = value
                    }
                }
            }

            if let date = extractDate(from: line) {
                currentDates.append(date)
            }

            // Confirmation Step
            if let fund = currentFund, !fund.isEmpty {
                 let finalAmount = currentAmount ?? amountInLine ?? 0.0
                 
                 // If we have a fund name AND an amount, we create the entry
                 if finalAmount > 0 {
                     if currentDates.count > 1 {
                         currentMode = "SIP"
                     }

                     let investment = ParsedInvestment(
                        fundName: fund,
                        type: "Mutual Fund",
                        investedAmount: finalAmount,
                        currentValue: nil,
                        units: currentUnits,
                        mode: "Lumpsum",
                        dates: currentDates
                     )

                     if !investments.contains(where: { $0.fundName == investment.fundName }) {
                         investments.append(investment)
                     }
                     
                     // Reset state for next item
                     currentFund = nil
                     currentAmount = nil
                     currentUnits = nil
                     currentDates = []
                 }
            }
        }

        return investments
    }

    private func extractNumericValue(from text: String) -> Double? {
        // Regex for numbers like 1,23,456.78 or 50000 (optional decimals)
        let pattern = #"[₹\s]?\s?[\d,]+(?:\.\d+)?"#
        if let range = text.range(of: pattern, options: .regularExpression) {
            let valueStr = String(text[range])
                .replacingOccurrences(of: "₹", with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespaces)
            return Double(valueStr)
        }
        return nil
    }

    private func extractDate(from text: String) -> Date? {
        // Regex for formats like DD/MM/YYYY, DD-MMM-YYYY
        let patterns = [
             #"\d{2}[-/]\d{2}[-/]\d{4}"#, // 12-01-2023
             #"\d{2}-[A-Za-z]{3}-\d{4}"#   // 12-Jan-2023
        ]

        for pattern in patterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                let dateStr = String(text[range])
                return parseDate(dateStr)
            }
        }
        return nil
    }

    private func parseDate(_ str: String) -> Date? {
        let formatter = DateFormatter()
        let formats = ["dd/MM/yyyy", "dd-MM-yyyy", "dd-MMM-yyyy", "dd MMM yyyy"]
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: str) {
                return date
            }
        }
        return nil
    }
}
