import Foundation
import SwiftUI
import PDFKit

@Observable
class ImportViewModel {
    var parsedInvestments: [ParsedInvestment] = []
    var isLoading = false
    var errorMessage: String?
    var showReviewList = false

    func processPDF(at url: URL) async {
        isLoading = true
        errorMessage = nil

        do {
            if url.pathExtension.lowercased() == "csv" {
                try await processCSV(at: url)
            } else {
                var results = try await PDFParserManager.shared.parsePDF(at: url)
                if results.isEmpty {
                    errorMessage = "No investments were detected in this PDF. Please check the document format."
                    showReviewList = false
                } else {
                    // Enrichment with historical data and current valuation
                    await MFService.shared.fetchMFData()
                    
                    for i in 0..<results.count {
                        let isin = results[i].isin ?? ""
                        let isMutualFund = isin.hasPrefix("INF")
                        
                        var totalCost: Double = 0
                        var processedUnits: Double = 0
                        var firstTransactionDate: Date?
                        
                        if isMutualFund {
                            if let scheme = MFService.shared.getSchemeByISIN(isin) {
                                results[i].schemeCode = scheme.schemeCode
                                results[i].fundName = scheme.name
                                
                                for j in 0..<results[i].transactions.count {
                                    let tx = results[i].transactions[j]
                                    if let historyNAV = await MFService.shared.fetchHistoricalNAV(schemeCode: scheme.schemeCode, date: tx.date) {
                                        results[i].transactions[j].nav = historyNAV
                                        results[i].transactions[j].amount = tx.units * historyNAV
                                        totalCost += results[i].transactions[j].amount
                                    } else {
                                        results[i].transactions[j].nav = scheme.nav
                                        results[i].transactions[j].amount = tx.units * scheme.nav
                                        totalCost += results[i].transactions[j].amount
                                    }
                                    processedUnits += tx.units
                                    if firstTransactionDate == nil || tx.date < firstTransactionDate! {
                                        firstTransactionDate = tx.date
                                    }
                                }
                                if let totalUnits = results[i].units ?? (processedUnits > 0 ? processedUnits : nil) {
                                    results[i].currentValue = totalUnits * scheme.nav
                                    results[i].units = totalUnits
                                }
                            }
                        } else {
                            // Equity Stock Enrichment
                            var symbol = results[i].symbol ?? ""
                            if !symbol.isEmpty && !symbol.contains(".") {
                                symbol = "\(symbol).NS" // Default to NSE for Upstox
                            }
                            
                            for j in 0..<results[i].transactions.count {
                                let tx = results[i].transactions[j]
                                if let historyPrice = await StockService.shared.fetchHistoricalPrice(symbol: symbol, date: tx.date) {
                                    results[i].transactions[j].nav = historyPrice
                                    results[i].transactions[j].amount = tx.units * historyPrice
                                    totalCost += results[i].transactions[j].amount
                                } else if let live = await StockService.shared.fetchPrice(symbol: symbol) {
                                    results[i].transactions[j].nav = live.currentPrice
                                    results[i].transactions[j].amount = tx.units * live.currentPrice
                                    totalCost += results[i].transactions[j].amount
                                }
                                processedUnits += tx.units
                                if firstTransactionDate == nil || tx.date < firstTransactionDate! {
                                    firstTransactionDate = tx.date
                                }
                            }
                            
                            if let live = await StockService.shared.fetchPrice(symbol: symbol) {
                                let totalUnits = results[i].units ?? (processedUnits > 0 ? processedUnits : nil)
                                results[i].currentValue = (totalUnits ?? 0) * live.currentPrice
                                results[i].units = totalUnits
                                results[i].symbol = symbol
                            }
                        }
                        
                        results[i].investedAmount = totalCost
                        if let firstDate = firstTransactionDate {
                            results[i].dates = [firstDate]
                        }
                    }
                    self.parsedInvestments = results
                    self.showReviewList = true
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func processCSV(at url: URL) async throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw PDFParsingError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let content = try String(contentsOf: url, encoding: .utf8)
        let results = parseCSV(content: content)
        
        if results.isEmpty {
             errorMessage = "No investments detected in CSV."
        } else {
             self.parsedInvestments = results
             self.showReviewList = true
        }
    }

    private func parseCSV(content: String) -> [ParsedInvestment] {
        var results: [ParsedInvestment] = []
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let parts = line.components(separatedBy: ",")
            if parts.count >= 2 {
                // Try to identify Name and Amount in columns
                let name = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                if let amount = Double(parts.last?.replacingOccurrences(of: "\"", with: "") ?? "") {
                    let investment = ParsedInvestment(
                        fundName: name,
                        type: "Mutual Fund",
                        investedAmount: amount,
                        currentValue: nil,
                        units: nil,
                        mode: "Lumpsum",
                        dates: [Date()]
                    )
                    results.append(investment)
                }
            }
        }
        return results
    }

    func generateImportEntries() -> [AssessmentInvestmentEntry] {
        let selected = parsedInvestments.filter { $0.isSelected }
        var newEntries: [AssessmentInvestmentEntry] = []
        for item in selected {
            newEntries.append(item.toAssessmentEntry())
        }
        // Success: Clean up
        parsedInvestments = []
        showReviewList = false
        return newEntries
    }

    func reset() {
        parsedInvestments = []
        showReviewList = false
        errorMessage = nil
        isLoading = false
    }
}
