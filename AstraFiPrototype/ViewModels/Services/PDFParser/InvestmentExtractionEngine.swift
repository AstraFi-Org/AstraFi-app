import Foundation

class InvestmentExtractionEngine {
    static let shared = InvestmentExtractionEngine()
    
    // --- Step 2 & 3: Raw Extraction & Normalization ---
    
    func parse(text: String) async -> [ParsedInvestment] {
        let lines = text.components(separatedBy: .newlines)
        var normalizedAssets: [String: NormalizedAsset] = [:]
        
        // 1. Scan for ISINs first to create anchor points
        let isinMap = identifyISINs(in: text)
        
        // 1. Process line by line for transactions
        var activeISIN: String?
        var activeAssetName: String?
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            let lowerLine = trimmed.lowercased()
            
            // Skip summary/balance lines to avoid double counting
            if lowerLine.contains("balance") || lowerLine.contains("closing") || lowerLine.contains("total") {
                continue
            }
            
            // --- A. Asset Identification (The Anchor) ---
            // Pattern: "ISIN: INF205K01MV6 INVES MCF D-GROW"
            if let isin = extractISIN(trimmed) {
                activeISIN = isin
                
                // Extract name: text after ISIN
                if let isinRange = trimmed.range(of: isin) {
                    let namePart = String(trimmed[isinRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                    if !namePart.isEmpty {
                        activeAssetName = namePart
                    }
                }
                continue // ISIN lines usually don't have transactions themselves
            }
            
            // --- B. Transaction Detection ---
            if let date = extractDate(trimmed) {
                // Must have a numeric value that looks like a quantity or amount
                let numbers = extractAllNumbers(trimmed)
                guard !numbers.isEmpty else { continue }
                
                // Identify quantity (Buy/Cr column)
                // In Upstox/NSDL: Date | Description | [Buy/Cr] | [Sell/Dr] | [Balance]
                // We pick the first decimal number that isn't part of a long ID
                let qty = identifyQuantity(in: trimmed, numbers: numbers)
                
                let amount = extractAmount(trimmed) // Might be nil in Upstox ledger
                let price = extractPrice(trimmed)   // Might be nil
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
                
                // Group by ISIN or Name
                let key = tx.isin ?? tx.assetName
                if var asset = normalizedAssets[key] {
                    asset.transactions.append(tx)
                    normalizedAssets[key] = asset
                } else {
                    normalizedAssets[key] = NormalizedAsset(
                        name: tx.assetName,
                        isin: tx.isin,
                        transactions: [tx]
                    )
                }
            }
        }
        
        // 3. Step 5 & 6: Enrichment & Calculation
        var finalInvestments: [ParsedInvestment] = []
        
        for asset in normalizedAssets.values {
            let enriched = await enrichAsset(asset)
            
            // Step 7: Final Model Construction
            let totalUnits = enriched.transactions.reduce(0.0) { $0 + $1.units }
            let investedAmt = enriched.transactions.reduce(0.0) { $0 + $1.amount }
            
            let parsed = ParsedInvestment(
                fundName: enriched.fundName,
                type: enriched.type,
                investedAmount: investedAmt,
                currentValue: nil, // Live value enriched by view models later
                units: totalUnits,
                mode: enriched.transactions.count > 1 ? "SIP" : "Lumpsum",
                dates: enriched.transactions.map { $0.date }.sorted(),
                transactions: enriched.transactions,
                isin: enriched.isin,
                quantity: totalUnits
            )
            
            finalInvestments.append(parsed)
        }
        
        return finalInvestments
    }
    
    // MARK: - Step 5: Enrichment Layer
    
    private func enrichAsset(_ asset: NormalizedAsset) async -> ParsedInvestment {
        var parsedTxs: [ParsedTransaction] = []
        
        // Step 6: Invested Amount Calculation (The ₹500 case)
        var totalInvested: Double = 0
        
        for tx in asset.transactions {
            var finalAmount = tx.amount ?? 0
            var finalPrice = tx.price ?? 0
            
            if finalAmount == 0 {
                if finalPrice > 0 {
                    finalAmount = abs(tx.quantity) * finalPrice
                } else {
                    // Fetch historical price/NAV
                    if let isin = asset.isin {
                        if isin.hasPrefix("INF") {
                            if let scheme = MFService.shared.getSchemeByISIN(isin) {
                                // Important: Fetch historical NAV for the EXACT transaction date
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
            
            parsedTxs.append(ParsedTransaction(
                date: tx.date,
                type: tx.type,
                units: tx.quantity,
                amount: finalAmount,
                nav: finalPrice
            ))
        }
        
        return ParsedInvestment(
            fundName: asset.name,
            type: asset.assetType,
            investedAmount: totalInvested, // ✅ Now accurately calculated
            mode: parsedTxs.count > 1 ? "SIP" : "Lumpsum",
            dates: parsedTxs.map { $0.date }.sorted(),
            transactions: parsedTxs,
            isin: asset.isin
        )
    }
    
    // MARK: - Extraction Helpers
    
    private func extractDate(_ line: String) -> Date? {
        let patterns = [
            #"\d{2}[/-]\d{2}[/-]\d{4}"#,
            #"\d{2}-[a-z]{3}-\d{4}"#,
            #"\d{2} [a-z]{3} \d{4}"#
        ]
        for pattern in patterns {
            if let range = line.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let dateStr = String(line[range])
                return parseDate(dateStr)
            }
        }
        return nil
    }
    
    private func parseDate(_ str: String) -> Date? {
        let formatter = DateFormatter()
        let formats = ["dd/MM/yyyy", "dd-MM-yyyy", "dd-MMM-yyyy", "dd MMM yyyy", "yyyy-MM-dd"]
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: str) {
                return date
            }
        }
        return nil
    }
    
    private func extractQuantity(_ line: String) -> Double? {
        let numbers = extractAllNumbers(line)
        return identifyQuantity(in: line, numbers: numbers)
    }
    
    private func identifyQuantity(in line: String, numbers: [Double]) -> Double {
        // Broad heuristic for units:
        // 1. Usually the FIRST decimal number on the line
        // 2. Often has 2-4 decimal places
        // 3. Excludes very large numbers (likely IDs)
        for num in numbers {
            if num > 0 && num < 1000000 {
                return num
            }
        }
        return 0
    }
    
    private func extractAmount(_ line: String) -> Double? {
        let matches = extractAllNumbers(line)
        if matches.count >= 2 {
            // Amount is usually the last or largest value on a transaction line
            return matches.max()
        }
        return nil
    }
    
    private func extractPrice(_ line: String) -> Double? {
        let matches = extractAllNumbers(line)
        if matches.count >= 3 {
            // Price is often the middle value: Qty | Price | Amount
            return matches[1]
        }
        return nil
    }
    
    private func extractAllNumbers(_ line: String) -> [Double] {
        let pattern = #"[\d,]+\.\d+"# // Look for decimal numbers
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsString = line as NSString
        let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsString.length))
        return matches.compactMap { m in
            let str = nsString.substring(with: m.range).replacingOccurrences(of: ",", with: "")
            return Double(str)
        }
    }
    
    private func extractISIN(_ line: String) -> String? {
        // Standard ISIN is 12 characters (e.g., INF205K01MV6)
        let pattern = #"(?:ISIN:?\s*)?((?:INF|INE)[A-Z0-9]{9})"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
            let nsString = line as NSString
            if let match = regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: nsString.length)) {
                return nsString.substring(with: match.range(at: 1)).uppercased()
            }
        }
        return nil
    }
    
    private func identifyISINs(in text: String) -> [String: String] {
        var map: [String: String] = [:]
        let pattern = #"(INF|INE)[A-Z0-9]{12}"# // Slightly loose to catch variations
        // ... implementation for bulk scan ...
        return map
    }
    
    private func extractPotentialAssetName(_ line: String) -> String? {
        // Skip lines that are purely numeric or dates
        if line.range(of: #"[A-Z]{3,}"#, options: .regularExpression) != nil && line.count > 10 {
            // Very simple heuristic: contains capitals and is long
            let parts = line.components(separatedBy: .newlines)
            return parts.first?.trimmingCharacters(in: .whitespaces)
        }
        return nil
    }
    
    private func detectType(_ line: String) -> String {
        let low = line.lowercased()
        if low.contains("sell") || low.contains("redem") || low.contains("/dr") || low.contains("debit") {
            return "Sell"
        }
        return "Buy"
    }
    
    private func deriveSymbol(_ name: String) -> String {
        // Derive stock symbol (e.g., "RELIANCE IND" -> "RELIANCE.NS")
        let first = name.components(separatedBy: " ").first ?? name
        return first.uppercased() + ".NS"
    }
}
