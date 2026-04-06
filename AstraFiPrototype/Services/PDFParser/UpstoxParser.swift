import Foundation

struct UpstoxParser: StatementParser {
    func parse(text: String) -> [ParsedInvestment] {
        var investments: [ParsedInvestment] = []
        let lines = text.components(separatedBy: .newlines)
        
        var isinDates: [String: [Date]] = [:]
        var currentISIN: String?
        var isReadingTransactions = false

        // Pass 1: Transaction History for Mode & Start Date
        for line in lines {
            let normalizedLine = line.lowercased()
            if normalizedLine.contains("transaction details") { isReadingTransactions = true; continue }
            if isReadingTransactions {
                let tokens = line.components(separatedBy: .whitespaces).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                if normalizedLine.contains("isin:") {
                    if let isinToken = tokens.first(where: { $0.hasPrefix("IN") || $0.hasPrefix("INF") || $0.hasPrefix("INE") }) {
                        currentISIN = isinToken
                    }
                }
                if let isin = currentISIN, let date = parseDate(tokens.first ?? "") {
                    if tokens.count >= 4 && !normalizedLine.contains("opening balance") && !normalizedLine.contains("closing balance") {
                        if isinDates[isin] == nil { isinDates[isin] = [] }
                        isinDates[isin]?.append(date)
                    }
                }
                if normalizedLine.contains("holding valuation") { isReadingTransactions = false }
            }
        }

        // Pass 2: Holdings & Enrichment
        for line in lines {
            let tokens = line.components(separatedBy: .whitespaces).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            if tokens.count < 3 { continue }
            if let isinIndex = tokens.firstIndex(where: { t in t.count >= 10 && (t.hasPrefix("IN") || t.hasPrefix("INF") || t.hasPrefix("INE")) }) {
                let isin = tokens[isinIndex]
                var valuation: Double?
                for i in (isinIndex+1..<tokens.count).reversed() {
                    if let val = extractNumericValue(from: tokens[i]) { valuation = val; break }
                }
                if let val = valuation {
                    var nameTokens: [String] = []
                    var currentIndex = isinIndex + 1
                    while currentIndex < tokens.count && extractNumericValue(from: tokens[currentIndex]) == nil {
                         nameTokens.append(tokens[currentIndex])
                         currentIndex += 1
                    }
                    let name = nameTokens.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                    let units = currentIndex < tokens.count ? (extractNumericValue(from: tokens[currentIndex]) ?? 0.0) : 0.0
                    
                    let historicalDates = isinDates[isin] ?? []
                    let mode = historicalDates.count > 1 ? "SIP" : "Lumpsum"
                    let startDate = historicalDates.min() ?? Date()
                    
                    let investment = ParsedInvestment(
                        fundName: name.isEmpty ? "Holding \(isin)" : name,
                        type: isin.hasPrefix("INF") ? "Mutual Fund" : "Equity Stock",
                        investedAmount: val,
                        currentValue: val,
                        units: units,
                        mode: mode,
                        dates: [startDate],
                        schemeCode: nil,
                        isin: isin
                    )
                    if !investments.contains(where: { $0.fundName == investment.fundName }) {
                        investments.append(investment)
                    }
                }
            }
        }
        
        return investments
    }
    
    private func extractNumericValue(from text: String) -> Double? {
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
    
    private func parseDate(_ str: String) -> Date? {
        let formatter = DateFormatter()
        let formats = ["dd-MM-yyyy", "dd-MMM-yyyy", "dd/MM/yyyy"]
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: str) {
                return date
            }
        }
        return nil
    }
}
