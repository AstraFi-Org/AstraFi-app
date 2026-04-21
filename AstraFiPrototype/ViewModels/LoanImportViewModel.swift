import Foundation
import SwiftUI

@Observable
class LoanImportViewModel {
    var parsedLoans: [ParsedLoan] = []
    var isLoading = false
    var errorMessage: String?
    var showReviewList = false

    func processLoanPDF(at url: URL) async {
        isLoading = true
        errorMessage = nil

        do {
            if url.pathExtension.lowercased() == "csv" {
                try await processCSV(at: url)
            } else {
                let results = try await LoanParserManager.shared.parseLoanPDF(at: url)
                handleResults(results)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
    
    func processLoanImage(_ image: UIImage) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let results = try await LoanParserManager.shared.parseLoanImage(image)
            handleResults(results)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func handleResults(_ results: [ParsedLoan]) {
        if results.isEmpty {
            errorMessage = "No loans were detected in this document."
        } else {
            self.parsedLoans = results
            self.showReviewList = true
        }
    }

    private func processCSV(at url: URL) async throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw PDFParsingError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let content = try String(contentsOf: url, encoding: .utf8)
        let results = parseCSV(content: content)
        
        if results.isEmpty {
             errorMessage = "No loans detected in CSV."
        } else {
             self.parsedLoans = results
             self.showReviewList = true
        }
    }

    private func parseCSV(content: String) -> [ParsedLoan] {
        var results: [ParsedLoan] = []
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let parts = line.components(separatedBy: ",")
            if parts.count >= 3 {
                let lender = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let amountStr = parts[1].replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespaces)
                let emiStr = parts[2].replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespaces)
                
                if let amount = Double(amountStr) {
                    let loan = ParsedLoan(
                        type: .personalLoan,
                        amount: amount,
                        interestRate: 0.0,
                        emi: Double(emiStr) ?? 0.0,
                        tenure: 12,
                        startDate: Date(),
                        outstanding: amount,
                        lender: lender
                    )
                    results.append(loan)
                }
            }
        }
        return results
    }

    func generateImportEntries() -> [AssessmentLoanEntry] {
        let selected = parsedLoans.filter { $0.isSelected }
        var newEntries: [AssessmentLoanEntry] = []
        for item in selected {
            newEntries.append(item.toAssessmentEntry())
        }
        // Success: Clean up
        parsedLoans = []
        showReviewList = false
        return newEntries
    }

    func reset() {
        parsedLoans = []
        showReviewList = false
        errorMessage = nil
        isLoading = false
    }
}
