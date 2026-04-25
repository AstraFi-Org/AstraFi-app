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

        // --- Repayment Schedule ---
        if normalizedText.contains("repayment schedule")
            || normalizedText.contains("amortization") {
            return .repaymentSchedule
        }

        // --- Sanction Letter ---
        // Covers: Bank of Baroda ("letter of sanction to the borrower"),
        //         standard "sanction letter", and other common sanction letter keywords
        if normalizedText.contains("sanction letter")
            || normalizedText.contains("letter of sanction")
            || normalizedText.contains("disbursement details")
            || normalizedText.contains("terms and conditions")
            || normalizedText.contains("permissible limit")
            || normalizedText.contains("moratorium")
            || normalizedText.contains("baroda gyan loan")
            || normalizedText.contains("education loan")
            || (normalizedText.contains("sanctioned") && normalizedText.contains("borrower")) {
            return .sanctionLetter
        }

        // --- Loan Statement ---
        if normalizedText.contains("loan account")
            || normalizedText.contains("loan statement")
            || normalizedText.contains("outstanding balance")
            || normalizedText.contains("closing balance") {
            return .statement
        }

        // --- Keyword fallback for statement ---
        if normalizedText.contains("principal")
            && normalizedText.contains("interest")
            && normalizedText.contains("emi") {
            return .statement
        }

        return .unknown
    }

    // MARK: - Parse from PDF file

    func parseLoanPDF(at url: URL) async throws -> [ParsedLoan] {
        let fullText = try await VisionOCRService.shared.extractTextFromPDF(at: url)
        return try await parseText(fullText)
    }

    // MARK: - Parse from UIImage (Gallery / Camera)

    func parseLoanImage(_ image: UIImage) async throws -> [ParsedLoan] {
        let text = try await VisionOCRService.shared.extractText(from: image)
        return try await parseText(text)
    }

    // MARK: - Core Parse Logic

    private func parseText(_ text: String) async throws -> [ParsedLoan] {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PDFParsingError.emptyExtraction
        }

        let type = detectLoanPDFType(from: text)

        // Primary parser based on detected type
        let primaryParser: LoanStatementParser
        switch type {
        case .sanctionLetter:
            primaryParser = SanctionLetterParser()
        case .statement:
            primaryParser = AstraLoanStatementParser()
        case .repaymentSchedule:
            primaryParser = RepaymentScheduleParser()
        case .unknown:
            primaryParser = SanctionLetterParser()
        }

        var results = primaryParser.parse(text: text)

        // If primary parser returned nothing, try all parsers as fallback
        if results.isEmpty {
            let fallbackParsers: [LoanStatementParser] = [
                SanctionLetterParser(),
                AstraLoanStatementParser(),
                RepaymentScheduleParser()
            ]
            for fallback in fallbackParsers {
                let fallbackResults = fallback.parse(text: text)
                if !fallbackResults.isEmpty {
                    results = fallbackResults
                    break
                }
            }
        }

        // Only throw if every parser failed
        if results.isEmpty {
            throw PDFParsingError.unsupportedFormat
        }

        return results
    }
}
