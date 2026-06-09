import Foundation

class InvestmentExtractionEngine {
    static let shared = InvestmentExtractionEngine()
    
    func parse(text: String) async -> [ParsedInvestment] {
        let lines = text.components(separatedBy: .newlines)
        var normalizedAssets: [String: NormalizedAsset] = [:]
        
        var activeISIN: String?
        var activeAssetName: String?
        
        // PDFKit sometimes wraps a single logical transaction row across two physical lines.
        // We carry a pending date forward so the continuation line (with quantity but no date)
        // can still be recorded correctly.
        var pendingDate: Date? = nil

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { pendingDate = nil; continue }
            let lowerLine = trimmed.lowercased()
            
            if lowerLine.contains("balance") || lowerLine.contains("closing") || lowerLine.contains("total") {
                pendingDate = nil
                continue
            }
            
            if let isin = extractISIN(trimmed) {
                activeISIN = isin
                pendingDate = nil
                if let isinRange = trimmed.range(of: isin) {
                    let namePart = String(trimmed[isinRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                    if !namePart.isEmpty { activeAssetName = namePart }
                }
                continue
            }
            
            // Handle both single-line and PDFKit-wrapped two-line transaction rows.
            let lineDate = extractDate(trimmed)
            let numbers = extractAllNumbers(trimmed)

            let effectiveDate: Date?
            if let d = lineDate {
                if numbers.isEmpty {
                    // Date present but quantity is on the next (wrapped) line — save and wait.
                    pendingDate = d
                    continue
                }
                effectiveDate = d
                pendingDate = nil
            } else if let pd = pendingDate {
                // Continuation line: use the date saved from the previous line.
                effectiveDate = pd
                pendingDate = nil
            } else {
                continue
            }

            guard let date = effectiveDate, !numbers.isEmpty else { continue }

            let qty = identifyQuantity(in: trimmed, numbers: numbers)
            let amount = extractAmount(trimmed)
            let price = extractPrice(trimmed)
            let type = detectType(trimmed)
            
            let tx = NormalizedTransaction(
                assetName: activeAssetName ?? "Unknown Asset",
                isin: activeISIN,
                date: date,
                quantity: type == "Sell" ? -abs(qty) : abs(qty),
                amount: amount,
                price: price,
                type: type
            )
            
            let key = tx.isin ?? tx.assetName
            if var asset = normalizedAssets[key] {
                asset.transactions.append(tx)
                normalizedAssets[key] = asset
            } else {
                normalizedAssets[key] = NormalizedAsset(name: tx.assetName, isin: tx.isin, transactions: [tx])
            }
        }
        
        var finalInvestments: [ParsedInvestment] = []
        for asset in normalizedAssets.values {
            let enriched = await enrichAsset(asset)
            let totalUnits = enriched.transactions.reduce(0.0) { $0 + $1.units }
            let investedAmt = enriched.transactions.reduce(0.0) { $0 + $1.amount }
            finalInvestments.append(ParsedInvestment(
                fundName: enriched.fundName,
                type: enriched.type,
                investedAmount: investedAmt,
                currentValue: nil,
                units: totalUnits,
                mode: enriched.transactions.count > 1 ? "SIP" : "Lumpsum",
                dates: enriched.transactions.map { $0.date }.sorted(),
                transactions: enriched.transactions,
                isin: enriched.isin,
                quantity: totalUnits
            ))
        }
        return finalInvestments
    }
    
    // MARK: - Enrichment

    private func enrichAsset(_ asset: NormalizedAsset) async -> ParsedInvestment {
        var parsedTxs: [ParsedTransaction] = []
        var totalInvested: Double = 0
        
        for tx in asset.transactions {
            var finalAmount = tx.amount ?? 0
            var finalPrice = tx.price ?? 0
            
            if finalAmount == 0 {
                if finalPrice > 0 {
                    finalAmount = abs(tx.quantity) * finalPrice
                } else {
                    if let isin = asset.isin {
                        if isin.hasPrefix("INF") {
                            if let scheme = MFService.shared.getSchemeByISIN(isin) {
                                let nav = await MFService.shared.fetchHistoricalNAV(schemeCode: scheme.schemeCode, date: tx.date)
                                finalPrice = nav ?? 0
                                finalAmount = abs(tx.quantity) * finalPrice
                            }
                        } else {
                            let symbol = deriveSymbol(asset.name)
                            let price = await StockService.shared.fetchHistoricalPrice(symbol: symbol, date: tx.date)
                            finalPrice = price ?? 0
                            finalAmount = abs(tx.quantity) * finalPrice
                        }
                    }
                }
            }
            totalInvested += finalAmount
            parsedTxs.append(ParsedTransaction(date: tx.date, type: tx.type, units: tx.quantity, amount: finalAmount, nav: finalPrice))
        }
        
        return ParsedInvestment(
            fundName: asset.name,
            type: asset.assetType,
            investedAmount: totalInvested,
            mode: parsedTxs.count > 1 ? "SIP" : "Lumpsum",
            dates: parsedTxs.map { $0.date }.sorted(),
            transactions: parsedTxs,
            isin: asset.isin
        )
    }
    
    // MARK: - Extraction Helpers
    
    private func extractDate(_ line: String) -> Date? {
        let patterns = [#"\d{2}[/-]\d{2}[/-]\d{4}"#, #"\d{2}-[a-z]{3}-\d{4}"#, #"\d{2} [a-z]{3} \d{4}"#]
        for pattern in patterns {
            if let range = line.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                return parseDate(String(line[range]))
            }
        }
        return nil
    }
    
    private func parseDate(_ str: String) -> Date? {
        let formatter = DateFormatter()
        for format in ["dd/MM/yyyy", "dd-MM-yyyy", "dd-MMM-yyyy", "dd MMM yyyy", "yyyy-MM-dd"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: str) { return date }
        }
        return nil
    }
    
    private func extractQuantity(_ line: String) -> Double? {
        identifyQuantity(in: line, numbers: extractAllNumbers(line))
    }
    
    private func identifyQuantity(in line: String, numbers: [Double]) -> Double {
        for num in numbers { if num > 0 && num < 1000000 { return num } }
        return 0
    }
    
    private func extractAmount(_ line: String) -> Double? {
        let matches = extractAllNumbers(line)
        return matches.count >= 2 ? matches.max() : nil
    }
    
    private func extractPrice(_ line: String) -> Double? {
        let matches = extractAllNumbers(line)
        return matches.count >= 3 ? matches[1] : nil
    }
    
    private func extractAllNumbers(_ line: String) -> [Double] {
        let pattern = #"[\d,]+\.\d+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsString = line as NSString
        return regex.matches(in: line, range: NSRange(location: 0, length: nsString.length)).compactMap {
            Double(nsString.substring(with: $0.range).replacingOccurrences(of: ",", with: ""))
        }
    }
    
    private func extractISIN(_ line: String) -> String? {
        let pattern = #"(?:ISIN:?\s*)?((?:INF|INE)[A-Z0-9]{9})"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
            let nsString = line as NSString
            if let match = regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: nsString.length)) {
                return nsString.substring(with: match.range(at: 1)).uppercased()
            }
        }
        return nil
    }
    
    private func identifyISINs(in text: String) -> [String: String] { return [:] }
    
    private func extractPotentialAssetName(_ line: String) -> String? {
        if line.range(of: #"[A-Z]{3,}"#, options: .regularExpression) != nil && line.count > 10 {
            return line.components(separatedBy: .newlines).first?.trimmingCharacters(in: .whitespaces)
        }
        return nil
    }
    
    private func detectType(_ line: String) -> String {
        let low = line.lowercased()
        if low.contains("sell") || low.contains("redem") || low.contains("/dr") || low.contains("debit") { return "Sell" }
        return "Buy"
    }
    
    private func deriveSymbol(_ name: String) -> String {
        return (name.components(separatedBy: " ").first ?? name).uppercased() + ".NS"
    }
}
