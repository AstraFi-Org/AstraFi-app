//
//  PlatformStatementParser.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 23/04/26.
//
import Foundation

// MARK: - Platform Detection

enum BrokerPlatform: String {
    case groww          = "Groww"
    case upstox         = "Upstox"
    case zerodha        = "Zerodha / Kite"
    case angelOne       = "Angel One"
    case hdfcSec        = "HDFC Securities"
    case iciciDirect    = "ICICI Direct"
    case motilalOswal   = "Motilal Oswal"
    case nsdlCAS        = "NSDL CAS"
    case cdslCAS        = "CDSL CAS"
    case genericAMC     = "AMC Statement"
    case unknown        = "Unknown"
}

// MARK: - Multi-Platform Parser

class PlatformStatementParser {
    static let shared = PlatformStatementParser()

    func canHandle(text: String) -> Bool {
        switch detectPlatform(text: text) {
        case .groww, .nsdlCAS, .cdslCAS, .genericAMC, .unknown:
            return false
        default:
            return true
        }
    }

    func parse(text: String) -> [ParsedInvestment] {
        switch detectPlatform(text: text) {
        case .upstox:       return UpstoxCASParser().parse(text: text)
        case .zerodha:      return ZerodhaParser().parse(text: text)
        case .angelOne:     return AngelOneParser().parse(text: text)
        case .hdfcSec:      return GenericHoldingParser().parse(text: text)
        case .iciciDirect:  return ICICIDirectParser().parse(text: text)
        case .motilalOswal: return GenericHoldingParser().parse(text: text)
        default:            return GenericHoldingParser().parse(text: text)
        }
    }

    func detectPlatform(text: String) -> BrokerPlatform {
        let t = text.lowercased()
        if t.contains("groww invest tech") || t.contains("groww.in") { return .groww }
        if t.contains("upstox securities") || t.contains("upstox") || t.contains("rksv securities") || t.contains("formerly epx uptech") { return .upstox }
        if t.contains("zerodha") || t.contains("kite by zerodha") || t.contains("console.zerodha") { return .zerodha }
        if t.contains("angel one") || t.contains("angel broking") || t.contains("angelone") { return .angelOne }
        if t.contains("hdfc securities") || t.contains("hdfcsec") { return .hdfcSec }
        if t.contains("icici direct") || t.contains("icicidirect") { return .iciciDirect }
        if t.contains("motilal oswal") || t.contains("mofsl") { return .motilalOswal }
        if t.contains("nsdl") && (t.contains("consolidated account statement") || t.contains("cas")) { return .nsdlCAS }
        if t.contains("cdsl") && (t.contains("consolidated account statement") || t.contains("cas")) { return .cdslCAS }
        if t.contains("folio") || (t.contains("scheme name") && t.contains("isin")) || t.contains("valuation") { return .genericAMC }
        return .unknown
    }
}

// MARK: - Shared Helpers

struct ParserHelpers {

    static func extractISIN(from text: String) -> String? {
        let pattern = #"\b(IN[FE][A-Z0-9]{9})\b"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let ns = text as NSString
            if let m = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)) {
                return ns.substring(with: m.range(at: 1)).uppercased()
            }
        }
        return nil
    }

    static func extractDate(from text: String) -> Date? {
        let formatter = DateFormatter()
        let tryPatterns: [(regex: String, formats: [String])] = [
            (#"\b(\d{2}/\d{2}/\d{4})\b"#,       ["dd/MM/yyyy"]),
            (#"\b(\d{2}-\d{2}-\d{4})\b"#,       ["dd-MM-yyyy"]),
            (#"\b(\d{2}-[A-Za-z]{3}-\d{4})\b"#,  ["dd-MMM-yyyy"]),
            (#"\b(\d{2} [A-Za-z]{3} \d{4})\b"#,  ["dd MMM yyyy"]),
            (#"\b(\d{4}-\d{2}-\d{2})\b"#,       ["yyyy-MM-dd"]),
        ]
        for (pattern, formats) in tryPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let ns = text as NSString
                if let m = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)) {
                    let dateStr = ns.substring(with: m.range(at: 1))
                    for fmt in formats {
                        formatter.dateFormat = fmt
                        if let d = formatter.date(from: dateStr) { return d }
                    }
                }
            }
        }
        return nil
    }

    static func extractAllNumbers(from text: String) -> [Double] {
        let pattern = #"(?<![A-Z0-9])(\d{1,10}(?:,\d{2,3})*(?:\.\d+)?)(?![A-Z0-9])"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = text as NSString
        return regex.matches(in: text, range: NSRange(location: 0, length: ns.length)).compactMap {
            let s = ns.substring(with: $0.range(at: 1)).replacingOccurrences(of: ",", with: "")
            return Double(s)
        }
    }

    static func cleanName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")
    }

    static func assetType(isin: String?, name: String) -> String {
        if let isin = isin, isin.hasPrefix("INF") { return "Mutual Fund" }
        let low = name.lowercased()
        if low.contains("fund") || low.contains("mf") || low.contains("scheme") { return "Mutual Fund" }
        if low.contains("etf") { return "ETF" }
        if low.contains("bond") || low.contains("ncd") || low.contains("debenture") { return "Fixed Income" }
        return "Equity"
    }

    static func makeHoldingInvestment(name: String, isin: String?, qty: Double, avgPrice: Double,
                                      currentValue: Double?, asOf date: Date) -> ParsedInvestment {
        let invested = qty * avgPrice
        let tx = ParsedTransaction(date: date, type: "Buy", units: qty, amount: invested, nav: avgPrice)
        return ParsedInvestment(
            fundName: cleanName(name),
            type: assetType(isin: isin, name: name),
            investedAmount: invested,
            currentValue: currentValue,
            units: qty,
            mode: "Lumpsum",
            dates: [date],
            transactions: [tx],
            isin: isin,
            symbol: nil,
            quantity: qty
        )
    }
}

// MARK: - Upstox CAS Parser
//
// Upstox monthly DIS/CAS PDFs have TWO parseable sections:
//
// SECTION A — Transaction Details (used to build tx history & invested amount)
// ─────────────────────────────────────────────────────────────────────────────
// Header row: Date | Transaction Description | Buy/Cr | Sell/Dr | Balance
// ISIN anchor: "ISIN: INF205K01MV6  INVES MCF D-GROW"
// Tx rows:     "05/03/2026  NSCCL/1100001000012414 Sett:1110142526228dpref#2524322361  2.41    2.41"
// Closing:     "31/03/2026  Closing Balance                                                    2.41"
//
// SECTION B — Holding Valuation (used to get current value & rate)
// ─────────────────────────────────────────────────────────────────
// Header: ISIN Code | Company Name | Current Bal | Free Bal | Value Date | Rate | Value
// Row:    "INF205K01MV6  INVES MCF D-GROW  2.41  2.41  30/03/2026  189.60  457.13"

class UpstoxCASParser {

    func parse(text: String) -> [ParsedInvestment] {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let holdingMap = parseHoldingValuation(lines: lines)
        let investmentMap = parseTransactionSection(lines: lines)

        if investmentMap.isEmpty {
            return holdingMap.map { (isin, holding) in
                ParserHelpers.makeHoldingInvestment(
                    name: holding.name,
                    isin: isin,
                    qty: holding.qty,
                    avgPrice: holding.rate,
                    currentValue: holding.value,
                    asOf: holding.valueDate
                )
            }
        }

        // Step 4: Merge holding data (current value) into transaction-derived investments.
        // IMPORTANT: Do NOT set investedAmount from holding rate here — the holding section
        // records the rate as of the *value date* (often month-end), NOT the purchase date.
        // ImportViewModel will fetch the correct historical NAV for each transaction date.
        var results: [ParsedInvestment] = []
        for (isin, var inv) in investmentMap {
            if let h = holdingMap[isin] {
                inv.currentValue = h.value
                // Only use holding qty to fill in missing units if transaction section had none
                if (inv.units ?? 0) == 0, h.qty > 0 {
                    inv.units = h.qty
                }
                // investedAmount is intentionally left as 0 here so ImportViewModel
                // fetches the correct historical NAV for the actual purchase date.
            }
            results.append(inv)
        }

        // Add any ISIN from holding section not found in transactions (e.g., transferred-in)
        for (isin, h) in holdingMap where investmentMap[isin] == nil {
            results.append(ParserHelpers.makeHoldingInvestment(
                name: h.name, isin: isin, qty: h.qty, avgPrice: h.rate,
                currentValue: h.value, asOf: h.valueDate
            ))
        }

        return results
    }

    // MARK: - Transaction Section Parser

    private func parseTransactionSection(lines: [String]) -> [String: ParsedInvestment] {
        var result: [String: ParsedInvestment] = [:]

        var currentISIN: String? = nil
        var currentName: String? = nil
        var currentTxs: [ParsedTransaction] = []

        func flushCurrent() {
            guard let isin = currentISIN, !currentTxs.isEmpty else { return }
            let name = currentName ?? isin
            let buyTxs = currentTxs.filter { $0.units > 0 }
            let totalUnits = buyTxs.reduce(0.0) { $0 + $1.units }
            let totalAmt = buyTxs.reduce(0.0) { $0 + $1.amount }
            result[isin] = ParsedInvestment(
                fundName: ParserHelpers.cleanName(name),
                type: ParserHelpers.assetType(isin: isin, name: name),
                investedAmount: totalAmt,
                currentValue: nil,
                units: totalUnits,
                mode: buyTxs.count > 1 ? "SIP" : "Lumpsum",
                dates: buyTxs.map { $0.date }.sorted(),
                transactions: currentTxs,
                isin: isin,
                quantity: totalUnits
            )
        }

        var inTransactionSection = false

        // PDFKit often wraps a single logical transaction row across two physical lines, e.g.:
        //   Line 1: "05/03/2026  NSCCL /1100001000012414 Sett:"     ← has date, no quantity
        //   Line 2: "1110142526228dpref#2524322361  2.41  2.41"      ← has quantity, no date
        // We carry the date forward with pendingDate so the continuation line can use it.
        var pendingDate: Date? = nil

        for line in lines {
            let low = line.lowercased()

            if low.contains("transaction details") && low.contains("from") {
                inTransactionSection = true
                pendingDate = nil
                continue
            }
            if low.contains("holding valuation") || low.contains("holdings balance") {
                flushCurrent()
                break
            }
            guard inTransactionSection else { continue }

            if let isin = extractISINFromLine(line) {
                flushCurrent()
                currentISIN = isin
                currentTxs = []
                pendingDate = nil
                currentName = nameAfterISIN(line: line, isin: isin)
                continue
            }

            guard currentISIN != nil else { continue }
            if low.contains("closing balance") || low.contains("opening balance") {
                pendingDate = nil
                continue
            }
            if low.contains("date") && low.contains("transaction") {
                pendingDate = nil
                continue
            }

            // ── Transaction row ───────────────────────────────────────────────────
            // PDFKit sometimes splits one row into two lines:
            //   Line with date but no quantity → save pendingDate, continue
            //   Line with quantity but no date → use pendingDate as effective date
            let lineDate = ParserHelpers.extractDate(from: line)
            let smallDecimals = extractSmallDecimals(from: line)

            let effectiveDate: Date?
            if let d = lineDate {
                if smallDecimals.isEmpty {
                    // Date present but quantity is on the next (wrapped) line — save and wait.
                    pendingDate = d
                    continue
                }
                // Date and quantity on the same line — normal case.
                effectiveDate = d
                pendingDate = nil
            } else if let pd = pendingDate {
                // Continuation line: quantity arrived, use the date from the previous line.
                effectiveDate = pd
                pendingDate = nil
            } else {
                continue
            }

            guard let date = effectiveDate, !smallDecimals.isEmpty else { continue }

            let buyCr = smallDecimals[0]
            let sellDr: Double = smallDecimals.count > 1 ? smallDecimals[1] : 0
            let isSell = low.contains("debit") || low.contains("sell") || (sellDr > 0 && buyCr == 0)
            let units = isSell ? -abs(sellDr) : abs(buyCr)
            guard units != 0 else { continue }

            let tx = ParsedTransaction(date: date, type: isSell ? "Sell" : "Buy", units: units, amount: 0, nav: 0)
            currentTxs.append(tx)
        }

        flushCurrent()
        return result
    }

    // MARK: - Holding Valuation Parser

    private struct HoldingRow {
        var name: String
        var qty: Double
        var rate: Double
        var value: Double
        var valueDate: Date
    }

    private func parseHoldingValuation(lines: [String]) -> [String: HoldingRow] {
        var result: [String: HoldingRow] = [:]
        var inHoldingSection = false

        for line in lines {
            let low = line.lowercased()
            if low.contains("holding valuation") || low.contains("holdings balance") {
                inHoldingSection = true
                continue
            }
            guard inHoldingSection else { continue }
            if low.contains("isin code") || low.contains("company name") ||
               low.contains("total valuation") || low.contains("total") && line.count < 20 { continue }
            if line.trimmingCharacters(in: .whitespaces).isEmpty { continue }

            guard let isin = ParserHelpers.extractISIN(from: line) else { continue }
            let name = companyName(from: line, isin: isin)
            let date = ParserHelpers.extractDate(from: line) ?? Date()
            let nums = extractSmallDecimals(from: removeISIN(line, isin: isin))
            guard nums.count >= 2 else { continue }

            let value = nums.last ?? 0
            let rate = nums.count >= 2 ? nums[nums.count - 2] : 0
            let qty = nums[0]
            guard qty > 0 else { continue }
            result[isin] = HoldingRow(name: name, qty: qty, rate: rate, value: value, valueDate: date)
        }
        return result
    }

    // MARK: - Helpers

    private func extractISINFromLine(_ line: String) -> String? {
        let pattern = #"ISIN\s*:?\s*(IN[FE][A-Z0-9]{9})"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let ns = line as NSString
            if let m = regex.firstMatch(in: line, range: NSRange(location: 0, length: ns.length)) {
                return ns.substring(with: m.range(at: 1)).uppercased()
            }
        }
        return ParserHelpers.extractISIN(from: line)
    }

    private func nameAfterISIN(line: String, isin: String) -> String? {
        if let range = line.range(of: "ISIN Name:", options: .caseInsensitive) {
            return String(line[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let range = line.range(of: isin, options: .caseInsensitive) {
            let after = String(line[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if after.count > 2 { return after }
        }
        return nil
    }

    private func extractSmallDecimals(from text: String) -> [Double] {
        var clean = text
        let datePatterns = [#"\d{2}/\d{2}/\d{4}"#, #"\d{2}-\d{2}-\d{4}"#,
                            #"\d{2}-[A-Za-z]{3}-\d{4}"#, #"\d{4}-\d{2}-\d{2}"#]
        for pat in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pat) {
                clean = regex.stringByReplacingMatches(in: clean, range: NSRange(clean.startIndex..., in: clean), withTemplate: " ")
            }
        }
        if let regex = try? NSRegularExpression(pattern: #"\b\d{12,}\b"#) {
            clean = regex.stringByReplacingMatches(in: clean, range: NSRange(clean.startIndex..., in: clean), withTemplate: " ")
        }
        if let regex = try? NSRegularExpression(pattern: #"#\d+"#) {
            clean = regex.stringByReplacingMatches(in: clean, range: NSRange(clean.startIndex..., in: clean), withTemplate: " ")
        }
        let pattern = #"(?<!\d)(\d{1,7}(?:,\d{2,3})*(?:\.\d{1,6})?)(?!\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = clean as NSString
        return regex.matches(in: clean, range: NSRange(location: 0, length: ns.length)).compactMap { m -> Double? in
            let s = ns.substring(with: m.range(at: 1)).replacingOccurrences(of: ",", with: "")
            guard let d = Double(s), d > 0, d < 10_000_000 else { return nil }
            return d
        }
    }

    private func companyName(from line: String, isin: String) -> String {
        let afterISIN: String
        if let range = line.range(of: isin, options: .caseInsensitive) {
            afterISIN = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        } else {
            afterISIN = line
        }
        if let range = afterISIN.range(of: #"\s+\d"#, options: .regularExpression) {
            return String(afterISIN[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        return afterISIN.components(separatedBy: "  ").first?.trimmingCharacters(in: .whitespaces) ?? afterISIN
    }

    private func removeISIN(_ line: String, isin: String) -> String {
        line.replacingOccurrences(of: isin, with: "", options: .caseInsensitive)
    }
}

// MARK: - Zerodha / Kite Parser

class ZerodhaParser {
    func parse(text: String) -> [ParsedInvestment] {
        let reportDate = ParserHelpers.extractDate(from: text) ?? Date()
        var results: [ParsedInvestment] = []
        let lines = text.components(separatedBy: .newlines)
        var inTable = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let low = trimmed.lowercased()
            if low.contains("instrument") && (low.contains("qty") || low.contains("avg cost")) {
                inTable = true; continue
            }
            guard inTable else { continue }
            if trimmed.isEmpty || low.hasPrefix("total") || low.hasPrefix("note") { continue }

            let isin = ParserHelpers.extractISIN(from: trimmed)
            let nums = extractSmallDecimals(from: trimmed)
            guard nums.count >= 2 else { continue }

            let parts = trimmed.components(separatedBy: "  ").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            guard let name = parts.first, name.count > 1, !isNumeric(name) else { continue }

            let qty = nums[0]; let avgCost = nums[1]
            let curValue: Double? = nums.count > 2 ? nums.max() : nil
            guard qty > 0 else { continue }
            results.append(ParserHelpers.makeHoldingInvestment(name: name, isin: isin, qty: qty, avgPrice: avgCost, currentValue: curValue, asOf: reportDate))
        }
        if results.isEmpty { return GenericHoldingParser().parse(text: text) }
        return results
    }

    private func isNumeric(_ s: String) -> Bool { Double(s.replacingOccurrences(of: ",", with: "")) != nil }
    private func extractSmallDecimals(from text: String) -> [Double] {
        let pattern = #"(?<!\d)(\d{1,7}(?:,\d{2,3})*(?:\.\d{1,6})?)(?!\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = text as NSString
        return regex.matches(in: text, range: NSRange(location: 0, length: ns.length)).compactMap { m -> Double? in
            let s = ns.substring(with: m.range(at: 1)).replacingOccurrences(of: ",", with: "")
            guard let d = Double(s), d > 0 else { return nil }
            return d
        }
    }
}

// MARK: - Angel One Parser

class AngelOneParser {
    func parse(text: String) -> [ParsedInvestment] {
        let reportDate = ParserHelpers.extractDate(from: text) ?? Date()
        var results: [ParsedInvestment] = []
        let lines = text.components(separatedBy: .newlines)
        var headerFound = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let low = trimmed.lowercased()
            if !headerFound {
                if (low.contains("stock") || low.contains("scrip") || low.contains("scheme")) && low.contains("qty") {
                    headerFound = true
                }
                continue
            }
            if trimmed.isEmpty || low.hasPrefix("total") || low.hasPrefix("grand") { continue }

            let isin = ParserHelpers.extractISIN(from: trimmed)
            let nums = ParserHelpers.extractAllNumbers(from: trimmed)
            guard nums.count >= 2 else { continue }

            let name = extractLeadingName(from: trimmed)
            guard name.count > 2 else { continue }

            let qty = nums[0]; let avgPrice = nums[1]
            let curValue: Double? = nums.count >= 3 ? nums.max() : nil
            guard qty > 0 else { continue }
            results.append(ParserHelpers.makeHoldingInvestment(name: name, isin: isin, qty: qty, avgPrice: avgPrice, currentValue: curValue, asOf: reportDate))
        }
        if results.isEmpty { return GenericHoldingParser().parse(text: text) }
        return results
    }

    private func extractLeadingName(from line: String) -> String {
        if let range = line.range(of: #"\b(IN[FE][A-Z0-9]{9})\b"#, options: .regularExpression) {
            return String(line[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let range = line.range(of: #"\b\d{1,6}(?:\.\d+)?\b"#, options: .regularExpression) {
            return String(line[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return line
    }
}

// MARK: - ICICI Direct Parser

class ICICIDirectParser {
    func parse(text: String) -> [ParsedInvestment] {
        let reportDate = ParserHelpers.extractDate(from: text) ?? Date()
        var results: [ParsedInvestment] = []
        let lines = text.components(separatedBy: .newlines)
        var inTable = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let low = trimmed.lowercased()
            if !inTable {
                if (low.contains("scrip name") || low.contains("stock name")) && low.contains("qty") {
                    inTable = true; continue
                }
                continue
            }
            if trimmed.isEmpty || low.hasPrefix("total") { continue }

            let isin = ParserHelpers.extractISIN(from: trimmed)
            let nums = ParserHelpers.extractAllNumbers(from: trimmed)
            guard nums.count >= 2 else { continue }

            let parts = trimmed.components(separatedBy: "  ").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            guard let name = parts.first, name.count > 2 else { continue }

            let qty = nums[0]; let avgPrice = nums[1]
            let curValue: Double? = nums.count >= 3 ? nums.max() : nil
            guard qty > 0 else { continue }
            results.append(ParserHelpers.makeHoldingInvestment(name: name, isin: isin, qty: qty, avgPrice: avgPrice, currentValue: curValue, asOf: reportDate))
        }
        if results.isEmpty { return GenericHoldingParser().parse(text: text) }
        return results
    }
}

// MARK: - Generic Holding Parser (fallback for any tabular demat statement)

class GenericHoldingParser {

    func parse(text: String) -> [ParsedInvestment] {
        var results: [ParsedInvestment] = []
        let reportDate = ParserHelpers.extractDate(from: text) ?? Date()
        let lines = text.components(separatedBy: .newlines)
        var prevLine = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            let low = trimmed.lowercased()
            if isSkippableLine(low) { prevLine = trimmed; continue }

            let isin = ParserHelpers.extractISIN(from: trimmed)
            let nums = extractSmallDecimals(from: trimmed)
            guard nums.count >= 2 else { prevLine = trimmed; continue }

            var name = extractLeadingName(from: trimmed)
            if name.count < 3 { name = extractLeadingName(from: prevLine) }
            guard name.count >= 3 else { prevLine = trimmed; continue }

            let qty = nums[0]; let avgPrice = nums[1]
            let curValue: Double? = nums.count >= 3 ? nums.last : nil
            guard qty > 0 && avgPrice > 0 else { prevLine = trimmed; continue }

            if let isin = isin, results.contains(where: { $0.isin == isin }) { prevLine = trimmed; continue }

            results.append(ParserHelpers.makeHoldingInvestment(name: name, isin: isin, qty: qty, avgPrice: avgPrice, currentValue: curValue, asOf: reportDate))
            prevLine = trimmed
        }
        return results
    }

    private func isSkippableLine(_ low: String) -> Bool {
        let skips = ["total", "grand total", "particulars", "sr no", "s.no", "sr.",
                     "note:", "disclaimer", "page", "date of report", "portfolio summary",
                     "holding statement", "account statement", "instrument", "stock name",
                     "scrip name", "scheme name", "fund name", "symbol", "isin", "qty",
                     "quantity", "units", "avg cost", "average cost", "avg price",
                     "ltp", "cmp", "market value", "current value", "p&l", "profit"]
        return skips.contains(where: { low.contains($0) }) && low.count < 80
    }

    private func extractLeadingName(from line: String) -> String {
        var result = line
        if let range = line.range(of: #"\b(IN[FE][A-Z0-9]{9})\b"#, options: .regularExpression) {
            result = String(line[..<range.lowerBound])
        } else if let range = line.range(of: #"(?<!\w)\d{1,10}(?:\.\d+)?(?!\w)"#, options: .regularExpression) {
            result = String(line[..<range.lowerBound])
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: "  ").first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func extractSmallDecimals(from text: String) -> [Double] {
        let pattern = #"(?<!\d)(\d{1,7}(?:,\d{2,3})*(?:\.\d{1,6})?)(?!\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = text as NSString
        return regex.matches(in: text, range: NSRange(location: 0, length: ns.length)).compactMap { m -> Double? in
            let s = ns.substring(with: m.range(at: 1)).replacingOccurrences(of: ",", with: "")
            guard let d = Double(s), d > 0, d < 10_000_000 else { return nil }
            return d
        }
    }
}
