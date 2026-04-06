import Foundation
import PDFKit

enum PDFType: String {
    case nsdlCAS = "NSDL CAS"
    case cdslCAS = "CDSL CAS"
    case amcStatement = "AMC Statement"
    case upstox = "Upstox Statement"
    case unknown = "Unknown Statement"
}

protocol StatementParser {
    func parse(text: String) -> [ParsedInvestment]
}

class PDFParserManager {
    static let shared = PDFParserManager()

    func detectPDFType(from text: String) -> PDFType {
        let normalizedText = text.lowercased()

        if normalizedText.contains("nsdl") && normalizedText.contains("consolidated account statement") {
            return .nsdlCAS
        } else if normalizedText.contains("cdsl") && normalizedText.contains("consolidated account statement") {
            return .cdslCAS
        } else if (normalizedText.contains("upstox") || normalizedText.contains("rksv") || normalizedText.contains("boid")) && normalizedText.contains("holding valuation") {
            return .upstox
        } else if normalizedText.contains("folio") || normalizedText.contains("scheme name") || normalizedText.contains("isin") || normalizedText.contains("valuation") {
            return .amcStatement
        }

        return .unknown
    }

    func parsePDF(at url: URL) async throws -> [ParsedInvestment] {
        // Start Security Scoped Access
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

        let type = detectPDFType(from: fullText)

        let parser: StatementParser
        switch type {
        case .nsdlCAS, .cdslCAS:
            parser = CASParser()
        case .amcStatement:
            parser = AMCParser()
        case .upstox:
            parser = UpstoxParser()
        case .unknown:
            parser = CASParser()
        }

        var results = parser.parse(text: fullText)
        
        // Multi-stage fallback: if specialized parser fails, try the robust Upstox row parser
        if results.isEmpty && type != .upstox {
             results = UpstoxParser().parse(text: fullText)
        }
        
        if results.isEmpty && type == .unknown {
            throw PDFParsingError.unsupportedFormat
        }
        
        return results
    }
}

enum PDFParsingError: LocalizedError {
    case accessDenied
    case invalidFile
    case emptyExtraction
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .accessDenied: return "Access to the file was denied."
        case .invalidFile: return "The file is not a valid PDF."
        case .emptyExtraction: return "No text could be extracted from the PDF."
        case .unsupportedFormat: return "Unable to identify investment data in this document. Please ensure it's a valid CAS PDF or Excel export."
        }
    }
}
