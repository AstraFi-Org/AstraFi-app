import Foundation
import PDFKit

enum LoanPDFType: String {
    case sanctionLetter = "Sanction Letter"
    case statement = "Loan Statement"
    case repaymentSchedule = "Repayment Schedule"
    case unknown = "Unknown Statement"
}

protocol LoanStatementParser {
    func parse(text: String) -> [ParsedLoan]
}

class LoanParserManager {
    static let shared = LoanParserManager()

    func detectLoanPDFType(from text: String) -> LoanPDFType {
        let normalizedText = text.lowercased()

        if normalizedText.contains("repayment schedule") || normalizedText.contains("amortization") {
            return .repaymentSchedule
        } else if normalizedText.contains("sanction letter") || normalizedText.contains("disbursement details") {
            return .sanctionLetter
        } else if normalizedText.contains("loan account") || normalizedText.contains("loan statement") {
            return .statement
        }

        // Keywords detection as fallback
        if normalizedText.contains("principal") && normalizedText.contains("interest") && normalizedText.contains("emi") {
             return .statement
        }

        return .unknown
    }

    func parseLoanPDF(at url: URL) async throws -> [ParsedLoan] {
        guard url.startAccessingSecurityScopedResource() else {
            throw PDFParsingError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let pdfDocument = PDFDocument(url: url) else {
            throw PDFParsingError.invalidFile
        }

        var fullText = ""
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i) {
                fullText += (page.string ?? "") + "\n"
            }
        }

        if fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw PDFParsingError.emptyExtraction
        }

        let type = detectLoanPDFType(from: fullText)

        let parser: LoanStatementParser
        switch type {
        case .sanctionLetter:
            parser = SanctionLetterParser()
        case .statement:
            parser = LoanStatementParserImpl()
        case .repaymentSchedule:
            parser = RepaymentScheduleParser()
        case .unknown:
             // Try a generic parser as fallback if some keywords matched
             parser = LoanStatementParserImpl()
        }

        let results = parser.parse(text: fullText)
        if results.isEmpty && type == .unknown {
             throw PDFParsingError.unsupportedFormat
        }
        return results
    }
}
