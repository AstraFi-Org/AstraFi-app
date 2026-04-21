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
        let fullText = try await VisionOCRService.shared.extractTextFromPDF(at: url)
        return try await parseText(fullText)
    }
    
    func parseLoanImage(_ image: UIImage) async throws -> [ParsedLoan] {
        let text = try await VisionOCRService.shared.extractText(from: image)
        return try await parseText(text)
    }
    
    private func parseText(_ text: String) async throws -> [ParsedLoan] {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw PDFParsingError.emptyExtraction
        }

        let type = detectLoanPDFType(from: text)

        let parser: LoanStatementParser
        switch type {
        case .sanctionLetter:
            parser = SanctionLetterParser()
        case .statement:
            parser = AstraLoanStatementParser()
        case .repaymentSchedule:
            parser = RepaymentScheduleParser()
        case .unknown:
             // Try sanction letter parser as it's the most robust for general loan docs
             parser = SanctionLetterParser()
        }

        let results = parser.parse(text: text)
        if results.isEmpty && type == .unknown {
             throw PDFParsingError.unsupportedFormat
        }
        return results
    }
}
