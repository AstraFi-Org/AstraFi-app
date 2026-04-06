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
                    errorMessage = "No investments were detected in this PDF."
                } else {
                    // Enrichment with current NAV
                    await MFService.shared.fetchMFData()
                    for i in 0..<results.count {
                        if let isin = results[i].isin, let scheme = MFService.shared.getSchemeByISIN(isin) {
                            results[i].schemeCode = scheme.schemeCode
                            if let units = results[i].units {
                                results[i].currentValue = units * scheme.nav
                            }
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
